const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn DefaultSeed(comptime Value: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Seed(
            Self,
            Value,
            deserialize,
        );

        fn deserialize(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try getty.deserialize(allocator, Value, deserializer);
        }
    };
}
