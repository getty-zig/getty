const std = @import("std");

const de = @import("../../../de.zig");

pub fn DefaultSeed(comptime Value: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.de.Seed(
            Self,
            Value,
            deserialize,
        );

        fn deserialize(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try de.deserialize(allocator, Value, deserializer);
        }
    };
}
