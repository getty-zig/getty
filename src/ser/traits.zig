const block = @import("traits/block.zig");
const attributes = @import("traits/attributes.zig");

/// Checks whether `T` contains a serialization block.
pub const has_sb = block.has_sb;

/// Checks whether `SB` defines serialization attributes for `T`.
pub const has_attributes = attributes.has_attributes;

/// Checks whether `attributes` is a serialization attribute list for `T`.
pub const is_attributes = attributes.is_attributes;
