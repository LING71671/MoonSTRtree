import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { basename, resolve } from "node:path";
import { createHash } from "node:crypto";
import { gzipSync } from "node:zlib";
import { auditGeoReport, summarizeGeoBuilds, summarizeGeoCases } from "./geo-report";
import { coordinateHash, geoInput, geoQueries } from "./geo-model";

const argument = (name: string) => process.argv.slice(2).find(value => value.startsWith(`--${name}=`))?.slice(name.length + 3);
const input = argument("input"), output = argument("output");
if (!input || !output) throw new Error("Usage: summarize-geo --input=complete.ndjson --output=summary.json [--cache=.bench/datasets]");
if (!output.endsWith(".json") || existsSync(resolve(output)) || existsSync(resolve(output + ".ndjson.gz"))) throw new Error("Use a new JSON output filename; retained evidence cannot be overwritten");
const bytes = readFileSync(resolve(input));
const { header, datasets, cases, footer } = auditGeoReport(bytes.toString("utf8"));
// Regenerate the actual deterministic inputs before publication. Matrix IDs
// alone cannot prove that the recorded geometry and query parameters agree.
const byInput = new Map<string, typeof cases>();
for (const item of cases) {
  const key = `${item.dataset}/${item.count}/${item.seed}`;
  const group = byInput.get(key) ?? []; group.push(item); byInput.set(key, group);
}
for (const dataset of datasets) {
  const input = geoInput(dataset as Parameters<typeof geoInput>[0], resolve(argument("cache") ?? ".bench/datasets"));
  if (coordinateHash(input.coordinates) !== dataset.coordinateSha256) throw new Error(`Recorded geo input changed: ${dataset.dataset}/${dataset.seed}`);
  const queries = new Map(geoQueries(input.coordinates).map(item => [item.id, item.query]));
  for (const item of byInput.get(`${dataset.dataset}/${dataset.count}/${dataset.seed}`)!) {
    if (JSON.stringify(item.query) !== JSON.stringify(queries.get(item.workload))) throw new Error(`Recorded geo query differs from the declared input: ${item.id}`);
  }
}
const grouped = (field: "group" | "dataset" | "kind" | "count") => Object.fromEntries([...new Set(cases.map(item => item[field]))].map(value => [value, summarizeGeoCases(cases.filter(item => item[field] === value))]));
const result = {
  schemaVersion: 1, scope: "Direct MoonBit 2D JavaScript comparison; not the four-provider website ranking or a memory benchmark",
  header, completion: footer, datasets,
  artifact: { raw: basename(output) + ".ndjson.gz", uncompressedSha256: createHash("sha256").update(bytes).digest("hex") },
  methodology: "Equal case weights over the common valid two-provider cohort; unsupported/errors retained in selected coverage; 5% band is descriptive, not statistical significance.",
  all: summarizeGeoCases(cases), construction: summarizeGeoBuilds(cases), byGroup: grouped("group"), byDataset: grouped("dataset"), byKind: grouped("kind"), byCount: grouped("count"),
  byK: Object.fromEntries([0, 1, 10, 100].map(k => [k, summarizeGeoCases(cases.filter(item => item.group === "knn" && item.query.k === k))])),
};
const raw = gzipSync(bytes, { level: 9 });
writeFileSync(resolve(output + ".ndjson.gz"), raw, { flag: "wx" });
writeFileSync(resolve(output), JSON.stringify({ ...result, artifact: { ...result.artifact, gzipSha256: createHash("sha256").update(raw).digest("hex") } }, null, 2) + "\n", { flag: "wx" });
console.log(JSON.stringify({ output, all: result.all, construction: result.construction, completion: footer }, null, 2));
