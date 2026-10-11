///|
/// Deterministic Linear Congruential Generator.
pub struct Rng {
  priv inner : @generator.Rng
} derive(Eq, Debug, Default)

///|
/// Constructs an Rng with initial seed.
pub fn Rng::new(seed : Int) -> Rng {
  Rng::{ inner: @generator.Rng::new(seed), }
}

///|
/// Generates uniform randomly distributed bounding boxes.
pub fn generate_uniform(
  rng : Rng,
  count : Int,
  domain_width? : Double = 1000.0,
  domain_height? : Double = 1000.0,
  max_box_size? : Double = 20.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_uniform(
    rng.inner,
    count,
    domain_width~,
    domain_height~,
    max_box_size~,
  )
  g
}

///|
/// Generates clustered Gaussian distributed bounding boxes.
pub fn generate_clustered(
  rng : Rng,
  count : Int,
  num_clusters? : Int = 5,
  domain_width? : Double = 1000.0,
  domain_height? : Double = 1000.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_clustered(
    rng.inner,
    count,
    num_clusters~,
    domain_width~,
    domain_height~,
  )
  g
}

///|
/// Generates diagonal collinear bounding boxes.
pub fn generate_diagonal(
  rng : Rng,
  count : Int,
  domain_size? : Double = 1000.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_diagonal(rng.inner, count, domain_size~)
  g
}

///|
/// Generates concentric nested bounding boxes.
pub fn generate_concentric(
  count : Int,
  center_x? : Double = 500.0,
  center_y? : Double = 500.0,
  step? : Double = 2.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_concentric(count, center_x~, center_y~, step~)
  g
}

///|
/// Generates regularly spaced grid tiles.
pub fn generate_grid(
  rows : Int,
  cols : Int,
  cell_size? : Double = 10.0,
  spacing? : Double = 2.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_grid(rows, cols, cell_size~, spacing~)
  g
}

///|
/// Generates uniform randomly distributed 3D bounding boxes.
pub fn generate_boxes_3d_uniform(
  rng : Rng,
  count : Int,
  domain_x? : Double = 1000.0,
  domain_y? : Double = 1000.0,
  domain_z? : Double = 1000.0,
  max_box_size? : Double = 20.0,
) -> Array[(Box3D, Int)] {
  let g = @generator.generate_boxes_3d_uniform(
    rng.inner,
    count,
    domain_x~,
    domain_y~,
    domain_z~,
    max_box_size~,
  )
  g
}

///|
/// Generates clustered Gaussian distributed 3D bounding boxes.
pub fn generate_boxes_3d_clustered(
  rng : Rng,
  count : Int,
  num_clusters? : Int = 4,
  domain_x? : Double = 1000.0,
  domain_y? : Double = 1000.0,
  domain_z? : Double = 1000.0,
) -> Array[(Box3D, Int)] {
  let g = @generator.generate_boxes_3d_clustered(
    rng.inner,
    count,
    num_clusters~,
    domain_x~,
    domain_y~,
    domain_z~,
  )
  g
}
