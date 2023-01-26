/// Checks if a type or value is a deserialization block or tuple.
pub const is_dbt = @import("traits/block.zig").is_dbt;

/// Checks if a value is a deserialization attribute list.
pub const is_attributes = @import("traits/attributes.zig").is_attributes;

/// Checks if a type contains a deserialization block.
pub const has_db = @import("traits/block.zig").has_db;

/// Checks if a type has associated deserialization attributes.
pub const has_attributes = @import("traits/attributes.zig").has_attributes;
