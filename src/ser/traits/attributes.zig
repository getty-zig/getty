const std = @import("std");

const is_sbt = @import("block.zig").is_sbt;
const is_tsb = @import("block.zig").is_tsb;
const Attributes = @import("../../attributes.zig").Attributes;

/// Checks to see if a type `T` has associated attributes.
pub fn has_attributes(
    /// A type with attributes.
    comptime T: type,
    /// A type-defined serialization block.
    comptime TSB: type,
) bool {
    comptime {
        return is_tsb(TSB) and @hasDecl(TSB, "attributes") and is_attributes(T, TSB.attributes);
    }
}

/// Validates a type's attributes.
pub fn is_attributes(
    /// The type containing the attributes being checked.
    comptime T: type,
    /// The attributes to validate.
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
