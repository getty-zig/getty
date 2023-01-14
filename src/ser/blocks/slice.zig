const std = @import("std");
const t = @import("getty/testing");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice and comptime !std.meta.trait.isZigString(T);
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    var s = try serializer.serializeSeq(value.len);
    const seq = s.seq();
    for (value) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}

test "serialize - slice" {
    try t.ser.run(serialize, &[_]i32{}, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });
    try t.ser.run(serialize, &[_]i32{ 1, 2, 3 }, &.{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
    });
}
