const std = @import("std");

const de = @import("../../de.zig").de;

/// An implementation of `getty.de.Seed` that ignores values.
///
/// `Ignored` is generally used to skip certain elements or entries during the
/// deserialization of aggregate types.
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
