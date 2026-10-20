// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "LING71671/moon_strtree"

version = "0.2.2"

readme = "README.md"

repository = "https://github.com/LING71671/MoonSTRtree"

license = "Apache-2.0"

keywords = [
  "spatial-index",
  "strtree",
  "rtree",
  "geometry",
  "gis",
  "bounding-box",
]

preferred_target = "wasm"

description = "STR-packed 2D, 3D and 4D spatial indexes with geometry and trajectory extensions for MoonBit"
