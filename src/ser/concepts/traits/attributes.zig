const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn has_attributes(comptime T: type, comptime SBT: type) bool {
    comptime {
        return getty.concepts.traits.is_sbt(SBT) and @hasDecl(SBT, "attributes") and is_attributes(T, SBT.attributes);
    }
}

pub fn is_attributes(comptime T: type, attributes: anytype) bool {
    comptime {
        const A = getty.Attributes(T, attributes);
        var a = A{};

        inline for (std.meta.fields(@TypeOf(attributes))) |field| {
            @field(a, field.name) = @field(attributes, field.name);
        }

        return std.meta.eql(a, attributes);
    }
}
