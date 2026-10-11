///|
/// Explicit trait-method exposure preserves the public API on moonc 0.10.14+.

///|
pub extend TreeStats with Eq::{equal, not_equal}

///|
pub extend TreeStats with @debug.Debug::{to_repr}

///|
pub extend TreeStats with Default::{default}
