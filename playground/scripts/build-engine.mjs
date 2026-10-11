import { spawnSync } from "node:child_process";
import { copyFileSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { moonToolchain } from "./moon-toolchain.mjs";

const playground = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const root = resolve(playground, "..");
const toolchain = moonToolchain(root);
const build = spawnSync(toolchain.moon, ["build", "--target", "js", "--release"], {
  cwd: root,
  env: toolchain.environment,
  stdio: "inherit",
  shell: false,
});
if (build.error) throw build.error;
if (build.status !== 0) process.exit(build.status ?? 1);
const generated = resolve(playground, "src/.generated");
mkdirSync(generated, { recursive: true });
const output = resolve(root, "_build/js/release/build/src/bridge/browser");
for (const [source, target] of [
  ["browser.js", "moon-engine.js"],
  ["browser.d.ts", "moon-engine.d.ts"],
  ["moonbit.d.ts", "moonbit.d.ts"],
]) {
  copyFileSync(resolve(output, source), resolve(generated, target));
}
const require = createRequire(resolve(playground, "package.json"));
const version = (name) =>
  JSON.parse(
    readFileSync(
      resolve(dirname(require.resolve(name)), "package.json"),
      "utf8",
    ),
  ).version;
const compiler = spawnSync(toolchain.moon, ["version"], {
  cwd: root,
  env: toolchain.environment,
  encoding: "utf8",
});
const sourceFiles = [resolve(root, "moon.mod"), resolve(root, "moon.pkg"), resolve(root, "moon_strtree.mbt")];
function collectSources(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) collectSources(path);
    else if (entry.name === "moon.pkg" || (entry.name.endsWith(".mbt") && !entry.name.endsWith("_test.mbt") && !entry.name.endsWith("_wbtest.mbt"))) sourceFiles.push(path);
  }
}
collectSources(resolve(root, "src"));
const sourceHash = createHash("sha256");
for (const path of sourceFiles.sort()) {
  sourceHash.update(relative(root, path).replaceAll("\\", "/") + "\0");
  sourceHash.update(readFileSync(path));
  sourceHash.update("\0");
}
writeFileSync(
  resolve(generated, "metadata.json"),
  JSON.stringify(
    {
      target: "JavaScript",
      compiler: toolchain.compilerVersion,
      moonVersion: compiler.stdout.trim().split("\n")[0],
      sourceSha256: sourceHash.digest("hex"),
      versions: { Flatbush: version("flatbush"), RBush: version("rbush"), "rbush-knn": version("rbush-knn") },
    },
    null,
    2,
  ) + "\n",
);
console.log("Browser engine compiled from the MoonBit core.");
