const getty = @import("../../lib.zig");

pub fn Seed(comptime Value: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.DeserializeSeed`.
        pub fn deserializeSeed(self: *Self) DS {
            return .{ .context = self };
        }

        const DS = getty.de.DeserializeSeed(
            *Self,
            Value,
            _DS.deserialize,
        );

        const _DS = struct {
            fn deserialize(self: *Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                _ = self;

                return try getty.deserialize(Value, deserializer);
            }
        };
    };
}