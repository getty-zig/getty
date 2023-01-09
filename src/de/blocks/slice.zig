const std = @import("std");
const t = @import("getty/testing");

const SliceVisitor = @import("../impls/visitor/slice.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice;
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
    return try switch (comptime std.meta.trait.isZigString(T)) {
        true => deserializer.deserializeString(allocator, visitor),
        false => deserializer.deserializeSeq(allocator, visitor),
    };
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return SliceVisitor(T);
}

test "deserialize - string" {
    {
        var arr = [_]u8{ 'a', 'b', 'c' };

        // No sentinel
        try t.de.run(&[_]t.Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 'a' },
            .{ .U8 = 'b' },
            .{ .U8 = 'c' },
            .{ .SeqEnd = {} },
        }, "abc");

        try t.de.run(&[_]t.Token{.{ .String = "abc" }}, @as([]u8, &arr));
        try t.de.run(&[_]t.Token{.{ .String = "abc" }}, @as([]const u8, &arr));
    }

    {
        var arr = [_:0]u8{ 'a', 'b', 'c' };

        // Sentinel
        try t.de.run(&[_]t.Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 'a' },
            .{ .U8 = 'b' },
            .{ .U8 = 'c' },
            .{ .SeqEnd = {} },
        }, "abc");

        try t.de.run(&[_]t.Token{.{ .String = "abc" }}, @as([:0]u8, &arr));
        try t.de.run(&[_]t.Token{.{ .String = "abc" }}, @as([:0]const u8, &arr));
    }
}
