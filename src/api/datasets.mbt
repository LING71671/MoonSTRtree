///|
/// Deterministic Linear Congruential Generator.
pub struct Rng {
  priv inner : @generator.Rng
} derive(Eq, Debug, Default)

///|
/// Constructs an Rng with initial seed.
pub fn Rng::new(seed : Int32) -> Rng {
  Rng::{ inner: @generator.Rng::new(seed), }
}

///|
/// Generates uniform randomly distributed bounding boxes.
pub fn generate_uniform(
  rng : Rng,
  count : Int32,
  domain_width~ : Double = 1000.0,
  domain_height~ : Double = 1000.0,
  max_box_size~ : Double = 20.0,
) -> Array[(Rect, Int32)] {
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
  count : Int32,
  num_clusters~ : Int32 = 5,
  domain_width~ : Double = 1000.0,
  domain_height~ : Double = 1000.0,
) -> Array[(Rect, Int32)] {
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
  count : Int32,
  domain_size~ : Double = 1000.0,
) -> Array[(Rect, Int32)] {
  let g = @generator.generate_diagonal(rng.inner, count, domain_size~)
  g
}

///|
/// Generates concentric nested bounding boxes.
pub fn generate_concentric(
  count : Int32,
  center_x~ : Double = 500.0,
  center_y~ : Double = 500.0,
  step~ : Double = 2.0,
) -> Array[(Rect, Int32)] {
  let g = @generator.generate_concentric(count, center_x~, center_y~, step~)
  g
}

///|
/// Generates regularly spaced grid tiles.
pub fn generate_grid(
  rows : Int32,
  cols : Int32,
  cell_size~ : Double = 10.0,
  spacing~ : Double = 2.0,
) -> Array[(Rect, Int32)] {
  let g = @generator.generate_grid(rows, cols, cell_size~, spacing~)
  g
}

///|
/// Generates uniform randomly distributed 3D bounding boxes.
pub fn generate_boxes_3d_uniform(
  rng : Rng,
  count : Int32,
  domain_x~ : Double = 1000.0,
  domain_y~ : Double = 1000.0,
  domain_z~ : Double = 1000.0,
  max_box_size~ : Double = 20.0,
) -> Array[(Box3D, Int32)] {
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
  count : Int32,
  num_clusters~ : Int32 = 4,
  domain_x~ : Double = 1000.0,
  domain_y~ : Double = 1000.0,
  domain_z~ : Double = 1000.0,
) -> Array[(Box3D, Int32)] {
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
