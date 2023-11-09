const std = @import("std");

const deserializeLeaky = @import("../../deserialize.zig").deserializeLeaky;
const SeedInterface = @import("../../interfaces/seed.zig").Seed;

/// The default implementation of `getty.de.Seed`.
///
/// `DefaultSeed` is the default seed used by Getty. All it does is call
/// `getty.deserializeLeaky`.
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

        fn deserialize(_: Self, ally: std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Err!Value {
            return try deserializeLeaky(ally, Value, deserializer);
        }
    };
}
