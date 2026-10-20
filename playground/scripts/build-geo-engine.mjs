import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { copyFileSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { moonToolchain } from "./moon-toolchain.mjs";

const playground = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const root = resolve(playground, "..");
const module = resolve(playground, "benchmarks/moonbit");
const toolchain = moonToolchain(root);
const result = spawnSync(toolchain.moon, ["build", "--target", "js", "--release"], {
  cwd: module,
  env: { ...toolchain.environment, MOON_WORK: resolve(module, "moon.work") },
  stdio: "inherit",
});
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);
const generated = resolve(playground, ".bench/geo-engine");
mkdirSync(generated, { recursive: true });
const compiled = resolve(module, "_build/js/release/build/LING71671/moon_strtree_geo_bench/moon_strtree_geo_bench.js");
copyFileSync(compiled, resolve(generated, "engine.mjs"));
copyFileSync(compiled.replace(/\.js$/, ".d.ts"), resolve(generated, "engine.d.mts"));
copyFileSync(resolve(dirname(compiled), "moonbit.d.ts"), resolve(generated, "moonbit.d.ts"));
const hash = bytes => createHash("sha256").update(bytes).digest("hex");
function sourceHash(base, includeRootFacade = false) {
  const files = [];
  function collect(directory) {
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const path = resolve(directory, entry.name);
      if (entry.isDirectory() && !entry.name.startsWith(".") && entry.name !== "_build") collect(path);
      else if (entry.isFile() && (entry.name === "moon.mod" || entry.name === "moon.pkg" || entry.name === "moon.work" || (entry.name.endsWith(".mbt") && !/_w?b?test\.mbt$/.test(entry.name)))) files.push(path);
    }
  }
  if (includeRootFacade) {
    files.push(...["moon.mod", "moon.pkg", "moon_strtree.mbt"].map(name => resolve(base, name)));
    collect(resolve(base, "src"));
  } else collect(base);
  const digest = createHash("sha256");
  for (const path of files.sort()) {
    digest.update(relative(base, path).replaceAll("\\", "/") + "\0");
    digest.update(readFileSync(path));
    digest.update("\0");
  }
  return digest.digest("hex");
}
const version = spawnSync(toolchain.moon, ["version"], { env: toolchain.environment, encoding: "utf8" });
if (version.status !== 0) throw new Error("Cannot record MoonBit toolchain version");
const metadata = {
  compiler: toolchain.compilerVersion,
  moonVersion: version.stdout.trim().split("\n")[0],
  target: "JavaScript", mode: "release", capacity: 16,
  moon: { module: "LING71671/moon_strtree", sourceSha256: sourceHash(root, true), resolution: "local moon.work member, not the registry release" },
  geo: { module: "totto2727/geo", version: "0.1.3", sourceSha256: sourceHash(resolve(module, ".mooncakes/totto2727/geo")) },
  bridgeSha256: sourceHash(module), artifactSha256: hash(readFileSync(compiled)),
};
writeFileSync(resolve(generated, "metadata.json"), JSON.stringify(metadata, null, 2) + "\n");
console.log(JSON.stringify(metadata, null, 2));
