///|
/// Explicit trait-method exposure preserves the public API on moonc 0.10.14+.

///|
pub extend Point2D with Eq::{equal, not_equal}

///|
pub extend Point2D with @debug.Debug::{to_repr}

///|
pub extend Point2D with Default::{default}

///|
pub extend Polygon2D with Eq::{equal, not_equal}

///|
pub extend Polygon2D with @debug.Debug::{to_repr}

///|
pub extend Polygon2D with Default::{default}

///|
pub extend StrPolygonIndex with Eq::{equal, not_equal}

///|
pub extend StrPolygonIndex with @debug.Debug::{to_repr}

///|
pub extend StrPolygonIndex with Default::{default}
