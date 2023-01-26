const std = @import("std");
const t = @import("../testing.zig");

const ArrayVisitor = @import("../impls/visitor/array.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Array;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeSeq(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return ArrayVisitor(T);
}

test "deserialize - array" {
    try t.run(deserialize, Visitor, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    }, [_]i32{});

    try t.run(deserialize, Visitor, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
    }, [3]i32{ 1, 2, 3 });

    try t.run(deserialize, Visitor, &.{
        .{ .Seq = .{ .len = 3 } },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .SeqEnd = {} },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 3 },
        .{ .I32 = 4 },
        .{ .SeqEnd = {} },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 5 },
        .{ .I32 = 6 },
        .{ .SeqEnd = {} },
        .{ .SeqEnd = {} },
    }, [3][2]i32{ .{ 1, 2 }, .{ 3, 4 }, .{ 5, 6 } });
}
