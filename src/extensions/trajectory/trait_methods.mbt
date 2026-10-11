///|
/// Explicit trait-method exposure preserves the public API on moonc 0.10.14+.

///|
pub extend StreamingTrajectoryCompressor with Eq::{equal, not_equal}

///|
pub extend StreamingTrajectoryCompressor with @debug.Debug::{to_repr}

///|
pub extend TrajectoryPoint with Eq::{equal, not_equal}

///|
pub extend TrajectoryPoint with @debug.Debug::{to_repr}

///|
pub extend TrajectoryPoint with Default::{default}

///|
pub extend TrajectorySegment with Eq::{equal, not_equal}

///|
pub extend TrajectorySegment with @debug.Debug::{to_repr}

///|
pub extend TrajectorySegment with Default::{default}

///|
pub extend TrajectorySimplificationResult with Eq::{equal, not_equal}

///|
pub extend TrajectorySimplificationResult with @debug.Debug::{to_repr}

///|
pub extend TrajectorySimplificationResult with Default::{default}

///|
pub extend TrajectoryWindowIndex with Eq::{equal, not_equal}

///|
pub extend TrajectoryWindowIndex with @debug.Debug::{to_repr}

///|
pub extend TrajectoryWindowIndex with Default::{default}
