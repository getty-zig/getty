const std = @import("std");
const t = @import("../testing.zig");

const PackedIntArrayVisitor = @import("../impls/visitor/packed_int_array.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "packed_int_array.PackedIntArrayEndian");
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
    return PackedIntArrayVisitor(T);
}

test "deserialize - std.PackedIntArray" {
    {
        var expected = std.PackedIntArray(u32, 0).init([0]u32{});

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        var expected = std.PackedIntArray(u32, 3).init([3]u32{ 1, 1, 1 });

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .I32 = 1 },
            .{ .I32 = 1 },
            .{ .I32 = 1 },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        var expected = std.PackedIntArray(i32, 3).initAllTo(-1);

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .I32 = -1 },
            .{ .I32 = -1 },
            .{ .I32 = -1 },
            .{ .SeqEnd = {} },
        }, expected);
    }
}
