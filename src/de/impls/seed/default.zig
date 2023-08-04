const std = @import("std");

const getty_deserialize = @import("../../deserialize.zig").deserialize;
const SeedInterface = @import("../../interfaces/seed.zig").Seed;

/// The default implementation of `getty.de.Seed`.
///
/// `DefaultSeed` is the default seed used by Getty. All it does is call
/// `getty.deserialize`.
pub fn DefaultSeed(
    /// The type to deserialize into.
    comptime Value: type,
) type {
    return struct {
        const Self = @This();

        pub usingnamespace SeedInterface(
            Self,
            Value,
            .{ .deserialize = deserialize },
        );

        fn deserialize(_: Self, ally: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try getty_deserialize(ally, Value, deserializer);
        }
    };
}
