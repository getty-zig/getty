const std = @import("std");

const SeedInterface = @import("../../interfaces/seed.zig").Seed;

/// An implementation of `getty.de.Seed` that ignores values.
///
/// `Ignored` is generally used to skip certain elements or entries during the
/// deserialization of aggregate types.
pub const Ignored = struct {
    const Value = Ignored;

    pub usingnamespace SeedInterface(
        Ignored,
        Value,
        .{ .deserialize = deserialize },
    );

    fn deserialize(i: Value, ally: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
        return try deserializer.deserializeIgnored(ally, i.visitor());
    }
};
