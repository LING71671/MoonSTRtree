declare module "rbush-knn" {
  import type RBush from "rbush";
  export default function knn<T extends {
    minX: number; minY: number; maxX: number; maxY: number;
  }>(tree: RBush<T>, x: number, y: number, k?: number,
    filter?: (item: T) => boolean, maxDistance?: number): T[];
}
