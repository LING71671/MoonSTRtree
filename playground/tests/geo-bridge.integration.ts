import { expect, test } from "bun:test";
import { pathToFileURL } from "node:url";
import { resolve } from "node:path";
import { referenceQuery } from "../src/engine/reference";
import { exactGeoAnswer, geoInput, geoQueries } from "../benchmarks/runtime/geo-model";

const module = await import(pathToFileURL(resolve(".bench/geo-engine/engine.mjs")).href);
const invoke = (tree: unknown, suffix: "moon" | "geo", query: ReturnType<typeof geoQueries>[number]["query"]) => {
  const [x1,y1,x2,y2]=query.bounds;
  switch(query.mode) {
    case "range": return module[`range_${suffix}`](tree,x1,y1,x2,y2);
    case "point": return module[`point_${suffix}`](tree,x1,y1);
    case "circle": return module[`circle_${suffix}`](tree,x1,y1,query.radius);
    case "knn": return module[`knn_${suffix}`](tree,x1,y1,query.k);
    case "segment": return suffix==="moon"?module.segment_moon(tree,x1,y1,x2,y2):null;
  }
};

for(const [dataset,count,kind] of [
  ["mixed",4097,"synthetic"], ["identical-bounds",4097,"boundary"], ["nested-bounds",4097,"boundary"],
  ["empty",0,"boundary"], ["singleton",1,"boundary"],
] as const) {
  test(`compiled MoonBit bridges: ${dataset} returns complete reference answers`,()=>{
    const input=geoInput({dataset,count,seed:42,kind},"unused");
    const trees={moon:module.build_moon(Array.from(input.coordinates)),geo:module.build_geo(Array.from(input.coordinates))};
    for(const workload of geoQueries(input.coordinates)) {
      const expected=referenceQuery(input.coordinates,workload.query);
      for(const suffix of ["moon","geo"] as const) {
        if(suffix==="geo"&&workload.group==="segment")continue;
        expect(exactGeoAnswer(invoke(trees[suffix],suffix,workload.query),expected,input,workload.query)).toBe(true);
      }
    }
    for(const k of [-1,0,count+1]) {
      const query={mode:"knn" as const,bounds:[500,500,500,500] as [number,number,number,number],radius:0,k};
      const expected=referenceQuery(input.coordinates,query);
      for(const suffix of ["moon","geo"] as const)expect(exactGeoAnswer(invoke(trees[suffix],suffix,query),expected,input,query)).toBe(true);
    }
  });
}
