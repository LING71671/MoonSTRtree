///|
/// A discrete 2D spatial grid cell with item density count and bounding rectangle.
pub struct GridCell {
  col : Int32
  row : Int32
  count : Int32
  bounds : @geometry.Rect
} derive(Eq, Debug, Default)

///|
/// Aggregated spatial grid density summary and hotspot metrics.
pub struct GridDensitySummary {
  cells : Array[GridCell]
  total_cells : Int32
  max_density : Int32
  avg_density : Double
  hotspot_cells : Array[GridCell]
} derive(Eq, Debug, Default)

///|
/// Partitions spatial items into uniform rectangular grid cells and computes density distribution.
/// cell_width: width of each grid column.
/// cell_height: height of each grid row.
/// hotspot_threshold: minimum item count for a cell to qualify as a hotspot (default: 1).
pub fn StrTree::aggregate_grid(
  self : StrTree,
  cell_width : Double,
  cell_height : Double,
  hotspot_threshold~ : Int32 = 1,
) -> GridDensitySummary {
  if self.root_index < 0 ||
    self.num_items == 0 ||
    cell_width <= 0.0 ||
    cell_height <= 0.0 {
    return GridDensitySummary::{
      cells: [],
      total_cells: 0,
      max_density: 0,
      avg_density: 0.0,
      hotspot_cells: [],
    }
  }

  let threshold = if hotspot_threshold < 1 { 1 } else { hotspot_threshold }

  // Extract center coordinates of all leaves
  let cell_coords : Array[(Int32, Int32)] = []
  for i = 0; i < self.boxes_min_x.length(); i = i + 1 {
    if self.child_count[i] == 0 && self.item_ids[i] >= 0 {
      let cx = (self.boxes_min_x[i] + self.boxes_max_x[i]) * 0.5
      let cy = (self.boxes_min_y[i] + self.boxes_max_y[i]) * 0.5
      let col = (cx / cell_width).floor().to_int()
      let row = (cy / cell_height).floor().to_int()
      cell_coords.push((col, row))
    }
  }

  let n = cell_coords.length()
  if n == 0 {
    return GridDensitySummary::{
      cells: [],
      total_cells: 0,
      max_density: 0,
      avg_density: 0.0,
      hotspot_cells: [],
    }
  }

  // Sort coordinates by col, then row
  cell_coords.sort_by(fn(a, b) {
    if a.0 != b.0 {
      a.0 - b.0
    } else {
      a.1 - b.1
    }
  })

  // Group contiguous identical grid cells
  let cells : Array[GridCell] = []
  let mut current_col = cell_coords[0].0
  let mut current_row = cell_coords[0].1
  let mut current_count = 1

  for i = 1; i < n; i = i + 1 {
    let (col, row) = cell_coords[i]
    if col == current_col && row == current_row {
      current_count = current_count + 1
    } else {
      let b_min_x = current_col.to_double() * cell_width
      let b_min_y = current_row.to_double() * cell_height
      let bounds = @geometry.Rect::new(
        b_min_x,
        b_min_y,
        b_min_x + cell_width,
        b_min_y + cell_height,
      )
      cells.push(GridCell::{
        col: current_col,
        row: current_row,
        count: current_count,
        bounds,
      })
      current_col = col
      current_row = row
      current_count = 1
    }
  }

  // Push final cell
  let b_min_x = current_col.to_double() * cell_width
  let b_min_y = current_row.to_double() * cell_height
  let bounds = @geometry.Rect::new(
    b_min_x,
    b_min_y,
    b_min_x + cell_width,
    b_min_y + cell_height,
  )
  cells.push(GridCell::{
    col: current_col,
    row: current_row,
    count: current_count,
    bounds,
  })

  let total_cells = cells.length()
  let mut max_density = 0
  let mut sum_count = 0
  let hotspots : Array[GridCell] = []

  for i = 0; i < total_cells; i = i + 1 {
    let cell = cells[i]
    if cell.count > max_density {
      max_density = cell.count
    }
    sum_count = sum_count + cell.count
    if cell.count >= threshold {
      hotspots.push(cell)
    }
  }

  // Sort hotspots in descending order of count
  hotspots.sort_by(fn(a, b) { b.count - a.count })

  let avg_density = if total_cells > 0 {
    sum_count.to_double() / total_cells.to_double()
  } else {
    0.0
  }

  GridDensitySummary::{
    cells,
    total_cells,
    max_density,
    avg_density,
    hotspot_cells: hotspots,
  }
}
