const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return T == std.BufSet;
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
    _ = ally;

    var s = try serializer.serializeSeq(value.count());
    const seq = s.seq();
    var it = value.iterator();
    while (it.next()) |key_ptr| {
        try seq.serializeElement(key_ptr.*);
    }
    return try seq.end();
}

test "serialize - buf set" {
    var set = std.BufSet.init(std.testing.allocator);
    defer set.deinit();

    try t.run(null, serialize, set, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    try set.insert("foobar");

    try t.run(null, serialize, set, &.{
        .{ .Seq = .{ .len = 1 } },
        .{ .String = "foobar" },
        .{ .SeqEnd = {} },
    });
}
