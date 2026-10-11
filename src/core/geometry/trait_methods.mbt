///|
/// Explicit trait-method exposure preserves the public API on moonc 0.10.14+.

///|
pub extend Box3D with Eq::{equal, not_equal}

///|
pub extend Box3D with @debug.Debug::{to_repr}

///|
pub extend Box3D with Default::{default}

///|
pub extend Box4D with Eq::{equal, not_equal}

///|
pub extend Box4D with @debug.Debug::{to_repr}

///|
pub extend Box4D with Default::{default}

///|
pub extend Rect with Eq::{equal, not_equal}

///|
pub extend Rect with @debug.Debug::{to_repr}

///|
pub extend Rect with Default::{default}

///|
pub extend SpatialPredicate with Eq::{equal, not_equal}

///|
pub extend SpatialPredicate with @debug.Debug::{to_repr}

///|
pub extend Triangle3D with Eq::{equal, not_equal}

///|
pub extend Triangle3D with @debug.Debug::{to_repr}

///|
pub extend Triangle3D with Default::{default}
