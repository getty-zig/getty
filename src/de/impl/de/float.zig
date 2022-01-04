const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn FloatDe(comptime Visitor: type) type {
    return struct {
        visitor: Visitor,

        const Self = @This();
        const impl = @"impl De"(Visitor);

        pub usingnamespace getty.De(
            Self,
            impl.de.deserialize,
        );
    };
}

fn @"impl De"(comptime Visitor: type) type {
    const Self = FloatDe(Visitor);

    return struct {
        pub const de = struct {
            pub fn deserialize(
                self: Self,
                allocator: ?std.mem.Allocator,
                comptime T: type,
                deserializer: anytype,
            ) @TypeOf(deserializer).Error!T {
                _ = allocator;

                return try deserializer.deserializeFloat(self.visitor);
            }
        };
    };
}
