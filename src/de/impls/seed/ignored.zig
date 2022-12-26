const std = @import("std");

const de = @import("../../../de.zig").de;

/// A `getty.de.Seed` implementation that ignores values.
pub const Ignored = struct {
    const Value = Ignored;

    pub usingnamespace de.Seed(
        Ignored,
        Value,
        .{ .deserialize = deserialize },
    );

    fn deserialize(i: Value, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
        return try deserializer.deserializeIgnored(allocator, i.visitor());
    }
};
