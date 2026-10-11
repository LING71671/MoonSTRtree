///|
/// Explicit trait-method exposure preserves the public API on moonc 0.10.14+.

///|
pub extend ClusterResult with Eq::{equal, not_equal}

///|
pub extend ClusterResult with @debug.Debug::{to_repr}

///|
pub extend ClusterResult with Default::{default}

///|
pub extend CompactClusterResult with Eq::{equal, not_equal}

///|
pub extend CompactClusterResult with @debug.Debug::{to_repr}

///|
pub extend CompactClusterResult with Default::{default}

///|
pub extend FlatBuffers with Eq::{equal, not_equal}

///|
pub extend FlatBuffers with @debug.Debug::{to_repr}

///|
pub extend FlatBuffers with Default::{default}

///|
pub extend FlatBuffers3D with Eq::{equal, not_equal}

///|
pub extend FlatBuffers3D with @debug.Debug::{to_repr}

///|
pub extend FlatBuffers3D with Default::{default}

///|
pub extend GridCell with Eq::{equal, not_equal}

///|
pub extend GridCell with @debug.Debug::{to_repr}

///|
pub extend GridCell with Default::{default}

///|
pub extend GridDensitySummary with Eq::{equal, not_equal}

///|
pub extend GridDensitySummary with @debug.Debug::{to_repr}

///|
pub extend GridDensitySummary with Default::{default}

///|
pub extend StrMeshTree3D with Eq::{equal, not_equal}

///|
pub extend StrMeshTree3D with @debug.Debug::{to_repr}

///|
pub extend StrMeshTree3D with Default::{default}

///|
pub extend StrTree with Eq::{equal, not_equal}

///|
pub extend StrTree with @debug.Debug::{to_repr}

///|
pub extend StrTree with Default::{default}

///|
pub extend StrTree3D with Eq::{equal, not_equal}

///|
pub extend StrTree3D with @debug.Debug::{to_repr}

///|
pub extend StrTree3D with Default::{default}

///|
pub extend StrTree4D with Eq::{equal, not_equal}

///|
pub extend StrTree4D with @debug.Debug::{to_repr}

///|
pub extend StrTree4D with Default::{default}

///|
pub extend TreeStats3D with Eq::{equal, not_equal}

///|
pub extend TreeStats3D with @debug.Debug::{to_repr}

///|
pub extend TreeStats3D with Default::{default}

///|
pub extend TreeStats4D with Eq::{equal, not_equal}

///|
pub extend TreeStats4D with @debug.Debug::{to_repr}

///|
pub extend TreeStats4D with Default::{default}
