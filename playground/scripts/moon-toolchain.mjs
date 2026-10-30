import { existsSync, readFileSync } from "node:fs";
import { resolve, delimiter } from "node:path";
import { spawnSync } from "node:child_process";

export function moonToolchain(root) {
  const configuration = resolve(root, ".moon-toolchain.json");
  const local = existsSync(configuration) ? JSON.parse(readFileSync(configuration, "utf8")) : {};
  const home = process.env.MOON_HOME ?? local.home;
  const environment = home ? { ...process.env, MOON_HOME: home, PATH: resolve(home, "bin") + delimiter + process.env.PATH } : process.env;
  const suffix = process.platform === "win32" ? ".exe" : "";
  const moon = home ? resolve(home, "bin", `moon${suffix}`) : "moon";
  const moonc = home ? resolve(home, "bin", `moonc${suffix}`) : "moonc";
  const compiler = spawnSync(moonc, ["-v"], { env: environment, encoding: "utf8" });
  if (compiler.error) throw compiler.error;
  if (compiler.status !== 0) throw new Error(compiler.stderr || "moonc version check failed");
  const text = compiler.stdout.trim();
  const match = /v?(\d+)\.(\d+)\.(\d+)/.exec(text);
  if (!match) throw new Error(`Cannot parse moonc version: ${text}`);
  const version = match.slice(1).map(Number);
  if (version[0] === 0 && (version[1] < 10 || (version[1] === 10 && version[2] < 18))) throw new Error(`moonc 0.10.18 or newer is required; found ${text}`);
  return { moon, compilerVersion: text, environment };
}
