const std = @import("std");

const is_sbt = @import("block.zig").is_sbt;
const is_tsb = @import("block.zig").is_tsb;
const Attributes = @import("../../attributes.zig").Attributes;

/// Checks whether `SB` defines serialization attributes for `T`.
pub fn has_attributes(
    /// A type to check.
    comptime T: type,
    /// A serialization block.
    comptime SB: type,
) bool {
    comptime {
        return (is_sbt(SB) or is_tsb(SB)) and @hasDecl(SB, "attributes") and is_attributes(T, SB.attributes);
    }
}

/// Checks whether `attributes` is a serialization attribute list for `T`.
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
