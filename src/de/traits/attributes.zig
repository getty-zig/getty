const std = @import("std");

const is_dbt = @import("block.zig").is_dbt;
const Attributes = @import("../../attributes.zig").Attributes;

/// Checks to see if a type `T` has associated attributes.
pub fn has_attributes(
    /// The type to check.
    comptime T: type,
    /// A serialization block or tuple.
    comptime DBT: type,
) bool {
    comptime {
        return is_dbt(DBT) and @hasDecl(DBT, "attributes") and is_attributes(T, DBT.attributes);
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
