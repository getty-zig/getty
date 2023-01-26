const std = @import("std");
const t = @import("../testing.zig");

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

test "deserialize - slice, string" {
    // No sentinel
    {
        var arr = [_]u8{ 'a', 'b', 'c' };

        try t.run(deserialize, Visitor, &.{.{ .String = "abc" }}, @as([]u8, &arr));
        try t.run(deserialize, Visitor, &.{.{ .String = "abc" }}, @as([]const u8, &arr));
    }

    // Sentinel
    {
        var arr = [_:0]u8{ 'a', 'b', 'c' };

        try t.run(deserialize, Visitor, &.{.{ .String = "abc" }}, @as([:0]u8, &arr));
        try t.run(deserialize, Visitor, &.{.{ .String = "abc" }}, @as([:0]const u8, &arr));
    }
}
