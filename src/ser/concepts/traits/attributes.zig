const std = @import("std");

const is_sbt = @import("../../../traits.zig").is_sbt;
const Attributes = @import("../../../attributes.zig").Attributes;

pub fn has_attributes(comptime T: type, comptime SBT: type) bool {
    comptime {
        return is_sbt(SBT) and @hasDecl(SBT, "attributes") and is_attributes(T, SBT.attributes);
    }
}

pub fn is_attributes(comptime T: type, attributes: anytype) bool {
    comptime {
        const A = Attributes(T, attributes);
        var a = A{};

        inline for (std.meta.fields(@TypeOf(attributes))) |field| {
            @field(a, field.name) = @field(attributes, field.name);
        }

        return std.meta.eql(a, attributes);
    }
}
