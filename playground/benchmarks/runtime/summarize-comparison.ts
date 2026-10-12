import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { basename, resolve } from "node:path";
import { createHash } from "node:crypto";
import { gzipSync } from "node:zlib";
import { PROFILES, SYNTHETIC_DATASETS, type ProfileName } from "../matrix/profiles";
import { makeQueries } from "../matrix/queries";
import catalog from "../data/sources.json";
import { median } from "./runner";

const argument = (name: string) => process.argv.slice(2).find(value => value.startsWith(`--${name}=`))?.slice(name.length + 3);
const input = argument("input"), output = argument("output");
if (!input || !output) throw new Error("Supply --input=raw.ndjson and --output=summary.json");
if (existsSync(resolve(output)) || existsSync(resolve(`${output}.ndjson.gz`))) throw new Error("Refusing to overwrite retained comparison evidence");
const bytes = readFileSync(resolve(input));
const records = bytes.toString("utf8").trim().split(/\r?\n/).map(line => JSON.parse(line));
const header = records[0], footer = records.at(-1);
if (header.type !== "header" || header.kind !== "engine-comparison" || header.schemaVersion !== 1 || footer.type !== "complete") throw new Error("A complete engine-comparison report is required");
const profile = PROFILES[header.profile as ProfileName];
if (!profile || ["counts", "capacities", "seeds", "batches", "warmups"].some(key => JSON.stringify(header.parameters[key]) !== JSON.stringify(profile[key as keyof typeof profile]))) throw new Error("Declared profile differs from the matrix");
if (!Number.isFinite(header.parameters.targetBatchMs) || header.parameters.targetBatchMs <= 0) throw new Error("Invalid batch duration");
if (!Array.isArray(header.groups) || header.groups.some((group: string) => !["all", "range", "point", "knn", "circle", "segment"].includes(group))) throw new Error("Invalid query groups");
const datasets = records.filter(record => record.type === "dataset");
const cases = records.filter(record => record.type === "case");
if (records.length !== datasets.length + cases.length + 2) throw new Error("Unexpected record type");
const inputs = new Map<string, { id: string; count: number; seed: number }>();
for (const id of SYNTHETIC_DATASETS) for (const count of profile.counts) for (const seed of profile.seeds)
  inputs.set(`${id}/${count}/${seed}`, { id, count, seed });
for (const source of catalog.sources) {
  const record = datasets.find(record => record.id === source.id);
  if (!Number.isInteger(record?.count) || record.count < 1 || record.provenance?.records !== record.count || record.provenance?.rawSha256 !== source.sha256) throw new Error(`Missing pinned public source: ${source.id}`);
  for (const seed of profile.seeds) inputs.set(`${source.id}/${record.count}/${seed}`, { id: source.id, count: record.count, seed });
}
const seenInputs = new Set<string>();
for (const record of datasets) {
  const key = `${record.id}/${record.count}/${record.seed}`;
  if (!inputs.has(key) || seenInputs.has(key)) throw new Error(`Unexpected/duplicate input: ${key}`);
  seenInputs.add(key);
}
if (seenInputs.size !== inputs.size) throw new Error("A declared input is absent");
const workloads = makeQueries(new Float64Array([0, 0, 1, 1])).filter(item => header.groups.includes("all") || header.groups.includes(item.group));
const expected = new Set<string>();
for (const { id, count, seed } of inputs.values()) for (const capacity of profile.capacities) for (const workload of workloads)
  expected.add(`${id}/${count}/capacity-${capacity}/seed-${seed}/${workload.id}`);
if (expected.size !== header.expectedCases || cases.length !== expected.size || footer.completed !== expected.size || footer.expectedCases !== expected.size) throw new Error("Incomplete declared matrix");
const providers = ["MoonSTRtree before", "MoonSTRtree after", "Flatbush", "RBush", "Linear scan"];
let failures = 0;
for (const item of cases) {
  if (item.id !== `${item.dataset}/${item.count}/capacity-${item.capacity}/seed-${item.seed}/${item.workload}` || !expected.delete(item.id)) throw new Error(`Unexpected/duplicate case: ${item.id}`);
  if (item.rows.length !== providers.length) throw new Error(`Missing providers: ${item.id}`);
  for (const [index, row] of item.rows.entries()) {
    if (row.name !== providers[index] || typeof row.valid !== "boolean" || typeof row.supported !== "boolean") throw new Error(`Invalid provider: ${item.id}`);
    if (row.supported && !row.valid) failures++;
    if (row.valid) {
      if (!row.supported || row.error !== null || row.hits !== item.expectedHits || !Number.isInteger(row.iterations) || row.iterations < 1 || row.samples.length !== profile.batches || !row.samples.every((value: number) => Number.isFinite(value) && value > 0) || median(row.samples) !== row.medianMs) throw new Error(`Invalid raw timing: ${item.id}/${row.name}`);
    } else if (row.medianMs !== null) throw new Error(`Invalid answer retained a score: ${item.id}/${row.name}`);
  }
}
if (expected.size || failures !== footer.failures) throw new Error("Retained records disagree with completion totals");
function summarize(selected: typeof cases) {
  const eligible = selected.filter(item => item.rows.every((row: { valid: boolean; medianMs: number | null }) => row.valid && row.medianMs !== null));
  const ratios = eligible.map(item => item.rows[0].medianMs / item.rows[1].medianMs);
  const geometricMean = (values: number[]) => values.length ? Math.exp(values.reduce((sum, value) => sum + Math.log(value), 0) / values.length) : null;
  return { selected: selected.length, eligible: eligible.length, beforeOverAfter: geometricMean(ratios), afterRelativeTo: Object.fromEntries(providers.slice(2).map((name, index) => [name, geometricMean(eligible.map(item => item.rows[index + 2].medianMs / item.rows[1].medianMs))])),
    pairedAgainstBefore: { faster: ratios.filter(value => value > 1.05).length, close: ratios.filter(value => value >= 1 / 1.05 && value <= 1.05).length, slower: ratios.filter(value => value < 1 / 1.05).length } };
}
const grouped = (field: string) => Object.fromEntries([...new Set(cases.map(item => item[field]))].map(value => [String(value), summarize(cases.filter(item => item[field] === value))]));
const result = { schemaVersion: 1, scope: "Targeted same-process engine comparison; not the full benchmark ranking", header, completion: footer,
  artifact: { sha256: createHash("sha256").update(bytes).digest("hex"), raw: `${basename(output)}.ndjson.gz` }, methodology: "Equal case weights in the common valid five-provider cohort; paired 5% ratio band is descriptive, not a significance test.",
  all: summarize(cases), byK: header.groups.includes("all") || header.groups.includes("knn") ? Object.fromEntries([1, 10, 100].map(k => [k, summarize(cases.filter(item => item.group === "knn" && item.query.k === k))])) : {}, byDataset: grouped("dataset"), byCapacity: grouped("capacity"), byCount: grouped("count") };
writeFileSync(resolve(output), JSON.stringify(result, null, 2) + "\n", { flag: "wx" });
writeFileSync(resolve(`${output}.ndjson.gz`), gzipSync(bytes), { flag: "wx" });
console.log(JSON.stringify({ output, all: result.all, completion: footer }, null, 2));
