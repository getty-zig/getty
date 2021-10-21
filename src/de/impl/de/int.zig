const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn De(comptime Visitor: type) type {
    return struct {
        visitor: Visitor,

        const Self = @This();
        const impl = @"impl De";

        pub usingnamespace getty.De(
            Self,
            impl.de(Self).deserialize,
        );
    };
}

const @"impl De" = struct {
    fn de(comptime Self: type) type {
        return struct {
            fn deserialize(self: Self, allocator: ?*std.mem.Allocator, comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
                _ = allocator;

                return try deserializer.deserializeInt(self.visitor);
            }
        };
    }
};
