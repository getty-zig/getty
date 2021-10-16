const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn De(comptime Visitor: type) type {
    return struct {
        visitor: Visitor,

        const Self = @This();

        pub usingnamespace getty.De(
            Self,
            deserialize,
        );

        fn deserialize(self: Self, allocator: ?*std.mem.Allocator, comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
            _ = allocator;

            return try deserializer.deserializeEnum(self.visitor);
        }
    };
}
