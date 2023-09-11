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
    v: anytype,
    /// A `getty.Serializer` interface value.
    s: anytype,
) @TypeOf(s).Err!@TypeOf(s).Ok {
    _ = ally;

    var ss = try s.serializeSeq(v.count());
    const seq = ss.seq();
    var it = v.iterator();
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
