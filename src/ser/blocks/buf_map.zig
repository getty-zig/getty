const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return T == std.BufMap;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty_serialize(ally, value.hash_map, serializer);
}

test "serialize - buf map" {
    var map = std.BufMap.init(std.testing.allocator);
    defer map.deinit();

    try t.run(null, serialize, map, &.{
        .{ .Map = .{ .len = 0 } },
        .{ .MapEnd = {} },
    });

    try map.put("1", "foobar");

    try t.run(null, serialize, map, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "1" },
        .{ .String = "foobar" },
        .{ .MapEnd = {} },
    });
}
