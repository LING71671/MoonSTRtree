///|
/// Explicit trait-method exposure preserves the public API on moonc 0.10.14+.

///|
pub extend STRBuildResult with Eq::{equal, not_equal}

///|
pub extend STRBuildResult with @debug.Debug::{to_repr}

///|
pub extend STRBuildResult with Default::{default}

///|
pub extend STRBuildResult3D with Eq::{equal, not_equal}

///|
pub extend STRBuildResult3D with @debug.Debug::{to_repr}

///|
pub extend STRBuildResult3D with Default::{default}

///|
pub extend STRItem with Eq::{equal, not_equal}

///|
pub extend STRItem with @debug.Debug::{to_repr}

///|
pub extend STRItem with Default::{default}

///|
pub extend STRItem3D with Eq::{equal, not_equal}

///|
pub extend STRItem3D with @debug.Debug::{to_repr}

///|
pub extend STRItem3D with Default::{default}

///|
pub extend STRNode with Eq::{equal, not_equal}

///|
pub extend STRNode with @debug.Debug::{to_repr}

///|
pub extend STRNode with Default::{default}

///|
pub extend STRNode3D with Eq::{equal, not_equal}

///|
pub extend STRNode3D with @debug.Debug::{to_repr}

///|
pub extend STRNode3D with Default::{default}
