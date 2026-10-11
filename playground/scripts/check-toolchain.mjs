import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { moonToolchain } from "./moon-toolchain.mjs";
const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
console.log(`Compiler requirement satisfied: ${moonToolchain(root).compilerVersion}`);
