///|
/// Deterministic Linear Congruential Generator (LCG).
pub struct Rng {
  mut state : Int
} derive(Eq, Debug, Default)

///|
/// Constructs an Rng with initial seed.
pub fn Rng::new(seed : Int) -> Rng {
  let initial = if seed == 0 { 12345 } else { seed }
  Rng::{ state: initial, }
}

///|
/// Returns next pseudo-random Int in [0, 2^31 - 1].
pub fn Rng::next_int(self : Rng) -> Int {
  self.state = (self.state * 1103515245 + 12345) & 0x7fffffff
  self.state
}

///|
/// Returns next pseudo-random Double in [0.0, 1.0).
pub fn Rng::next_double(self : Rng) -> Double {
  let val = self.next_int()
  val.to_double() / 2147483648.0
}

///|
/// Returns next Double in [min, max).
pub fn Rng::next_range(self : Rng, min : Double, max : Double) -> Double {
  min + self.next_double() * (max - min)
}

///|
/// Returns next Gaussian distributed Double using central limit approximation.
pub fn Rng::next_gaussian(self : Rng, mean : Double, stddev : Double) -> Double {
  let mut sum = 0.0
  for i = 0; i < 12; i = i + 1 {
    sum = sum + self.next_double()
  }
  let standard_normal = sum - 6.0
  mean + standard_normal * stddev
}

///|
/// Generates uniform randomly distributed bounding boxes.
pub fn generate_uniform(
  rng : Rng,
  count : Int,
  domain_width? : Double = 1000.0,
  domain_height? : Double = 1000.0,
  max_box_size? : Double = 20.0,
) -> Array[(@geometry.Rect, Int)] {
  let result : Array[(@geometry.Rect, Int)] = []
  for i = 0; i < count; i = i + 1 {
    let x = rng.next_range(0.0, domain_width)
    let y = rng.next_range(0.0, domain_height)
    let w = rng.next_range(1.0, max_box_size)
    let h = rng.next_range(1.0, max_box_size)
    result.push((@geometry.Rect::new(x, y, x + w, y + h), i))
  }
  result
}

///|
/// Generates clustered Gaussian distributed bounding boxes around multiple centroids.
pub fn generate_clustered(
  rng : Rng,
  count : Int,
  num_clusters? : Int = 5,
  domain_width? : Double = 1000.0,
  domain_height? : Double = 1000.0,
) -> Array[(@geometry.Rect, Int)] {
  let result : Array[(@geometry.Rect, Int)] = []
  let cluster_centers_x : Array[Double] = []
  let cluster_centers_y : Array[Double] = []

  let k = if num_clusters < 1 { 1 } else { num_clusters }
  for c = 0; c < k; c = c + 1 {
    cluster_centers_x.push(rng.next_range(100.0, domain_width - 100.0))
    cluster_centers_y.push(rng.next_range(100.0, domain_height - 100.0))
  }

  for i = 0; i < count; i = i + 1 {
    let c = i % k
    let cx = cluster_centers_x[c]
    let cy = cluster_centers_y[c]
    let x = rng.next_gaussian(cx, 30.0)
    let y = rng.next_gaussian(cy, 30.0)
    let w = rng.next_range(2.0, 15.0)
    let h = rng.next_range(2.0, 15.0)
    result.push((@geometry.Rect::new(x, y, x + w, y + h), i))
  }
  result
}

///|
/// Generates diagonal collinear bounding boxes testing degenerate slicing.
pub fn generate_diagonal(
  rng : Rng,
  count : Int,
  domain_size? : Double = 1000.0,
) -> Array[(@geometry.Rect, Int)] {
  let result : Array[(@geometry.Rect, Int)] = []
  for i = 0; i < count; i = i + 1 {
    let t = rng.next_range(0.0, domain_size)
    let jitter_x = rng.next_range(-5.0, 5.0)
    let jitter_y = rng.next_range(-5.0, 5.0)
    let x = t + jitter_x
    let y = t + jitter_y
    let w = rng.next_range(1.0, 10.0)
    let h = rng.next_range(1.0, 10.0)
    result.push((@geometry.Rect::new(x, y, x + w, y + h), i))
  }
  result
}

///|
/// Generates concentric nested bounding boxes around a common center.
pub fn generate_concentric(
  count : Int,
  center_x? : Double = 500.0,
  center_y? : Double = 500.0,
  step? : Double = 2.0,
) -> Array[(@geometry.Rect, Int)] {
  let result : Array[(@geometry.Rect, Int)] = []
  for i = 0; i < count; i = i + 1 {
    let radius = (i + 1).to_double() * step
    result.push(
      (
        @geometry.Rect::new(
          center_x - radius,
          center_y - radius,
          center_x + radius,
          center_y + radius,
        ),
        i,
      ),
    )
  }
  result
}

///|
/// Generates regularly spaced grid tiles.
pub fn generate_grid(
  rows : Int,
  cols : Int,
  cell_size? : Double = 10.0,
  spacing? : Double = 2.0,
) -> Array[(@geometry.Rect, Int)] {
  let result : Array[(@geometry.Rect, Int)] = []
  let mut id = 0
  for r = 0; r < rows; r = r + 1 {
    for c = 0; c < cols; c = c + 1 {
      let x = c.to_double() * (cell_size + spacing)
      let y = r.to_double() * (cell_size + spacing)
      result.push((@geometry.Rect::new(x, y, x + cell_size, y + cell_size), id))
      id = id + 1
    }
  }
  result
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
) -> Array[(@geometry.Box3D, Int)] {
  let result : Array[(@geometry.Box3D, Int)] = []
  for i = 0; i < count; i = i + 1 {
    let x = rng.next_range(0.0, domain_x)
    let y = rng.next_range(0.0, domain_y)
    let z = rng.next_range(0.0, domain_z)
    let w = rng.next_range(1.0, max_box_size)
    let h = rng.next_range(1.0, max_box_size)
    let d = rng.next_range(1.0, max_box_size)
    result.push((@geometry.Box3D::new(x, y, z, x + w, y + h, z + d), i))
  }
  result
}

///|
/// Generates clustered Gaussian distributed 3D bounding boxes around multiple centroids.
pub fn generate_boxes_3d_clustered(
  rng : Rng,
  count : Int,
  num_clusters? : Int = 4,
  domain_x? : Double = 1000.0,
  domain_y? : Double = 1000.0,
  domain_z? : Double = 1000.0,
) -> Array[(@geometry.Box3D, Int)] {
  let result : Array[(@geometry.Box3D, Int)] = []
  let cluster_centers_x : Array[Double] = []
  let cluster_centers_y : Array[Double] = []
  let cluster_centers_z : Array[Double] = []

  let k = if num_clusters < 1 { 1 } else { num_clusters }
  for c = 0; c < k; c = c + 1 {
    cluster_centers_x.push(rng.next_range(100.0, domain_x - 100.0))
    cluster_centers_y.push(rng.next_range(100.0, domain_y - 100.0))
    cluster_centers_z.push(rng.next_range(100.0, domain_z - 100.0))
  }

  for i = 0; i < count; i = i + 1 {
    let c = i % k
    let cx = cluster_centers_x[c]
    let cy = cluster_centers_y[c]
    let cz = cluster_centers_z[c]
    let x = rng.next_gaussian(cx, 30.0)
    let y = rng.next_gaussian(cy, 30.0)
    let z = rng.next_gaussian(cz, 30.0)
    let w = rng.next_range(2.0, 15.0)
    let h = rng.next_range(2.0, 15.0)
    let d = rng.next_range(2.0, 15.0)
    result.push((@geometry.Box3D::new(x, y, z, x + w, y + h, z + d), i))
  }
  result
}
