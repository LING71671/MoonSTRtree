///|
/// Explicit trait-method exposure preserves the public API on moonc 0.10.14+.

///|
pub extend GeofenceEvent with Eq::{equal, not_equal}

///|
pub extend GeofenceEvent with @debug.Debug::{to_repr}

///|
pub extend GeofenceMonitor with Eq::{equal, not_equal}

///|
pub extend GeofenceMonitor with @debug.Debug::{to_repr}

///|
pub extend GeofenceMonitor with Default::{default}
