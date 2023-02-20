const block = @import("traits/block.zig");
const attributes = @import("traits/attributes.zig");

/// Checks whether `T` contains a serialization block.
pub const has_sb = block.has_sb;

/// Checks if `sbt` is a serialization block or tuple.
pub const is_sbt = block.is_sbt;

/// Validates a type-defined serialization block.
pub const is_tsb = block.is_tsb;

/// Checks whether `SB` defines serialization attributes for `T`.
pub const has_attributes = attributes.has_attributes;

/// Checks whether `attributes` is a serialization attribute list for `T`.
pub const is_attributes = attributes.is_attributes;
