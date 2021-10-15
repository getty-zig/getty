const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn DefaultSeed(comptime Value: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Seed`.
        pub usingnamespace getty.de.Seed(
            *Self,
            Value,
            deserialize,
        );

        fn deserialize(self: *Self, allocator: ?*std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;

            return try getty.deserialize(allocator, Value, deserializer);
        }
    };
}
