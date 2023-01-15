const std = @import("std");

const is_dbt = @import("block.zig").is_dbt;
const is_tdb = @import("block.zig").is_tdb;
const Attributes = @import("../../attributes.zig").Attributes;

/// Checks whether `DB` defines deserialization attributes for `T`.
pub fn has_attributes(
    /// A type to check.
    comptime T: type,
    /// A deserialization block.
    comptime DB: type,
) bool {
    comptime {
        return (is_dbt(DB) or is_tdb(DB)) and @hasDecl(DB, "attributes") and is_attributes(T, DB.attributes);
    }
}

/// Checks whether `attributes` is a deserialization attribute list for `T`.
pub fn is_attributes(
    /// A type that `attributes` applies to.
    comptime T: type,
    /// An attribute list to check.
    attributes: anytype,
) bool {
    comptime {
        const A = Attributes(T, attributes);
        var a = A{};

        inline for (std.meta.fields(@TypeOf(attributes))) |field| {
            @field(a, field.name) = @field(attributes, field.name);
        }

        return std.meta.eql(a, attributes);
    }
}
