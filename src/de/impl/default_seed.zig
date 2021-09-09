const getty = @import("../../lib.zig");

const Allocator = @import("std").mem.Allocator;

pub fn DefaultSeed(comptime Value: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Seed`.
        pub usingnamespace getty.de.Seed(
            *Self,
            Value,
            _DS.deserialize,
        );

        const _DS = struct {
            fn deserialize(self: *Self, allocator: ?*Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                _ = self;

                return try getty.deserialize(allocator, Value, deserializer);
            }
        };
    };
}
