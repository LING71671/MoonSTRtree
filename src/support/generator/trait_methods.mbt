///|
/// Explicit trait-method exposure preserves the public API on moonc 0.10.14+.

///|
pub extend Rng with Eq::{equal, not_equal}

///|
pub extend Rng with @debug.Debug::{to_repr}

///|
pub extend Rng with Default::{default}
