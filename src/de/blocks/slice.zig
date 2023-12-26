const require = @import("protest").require;
const std = @import("std");

const isString = @import("../../helpers.zig").isString;
const SliceVisitor = @import("../impls/visitor/slice.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try switch (comptime isString(T)) {
        true => deserializer.deserializeString(ally, visitor),
        false => deserializer.deserializeSeq(ally, visitor),
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
    var no_sentinel = [_]u8{ 'a', 'b', 'c' };
    var sentinel = [_:0]u8{ 'a', 'b', 'c' };

    const tests = .{
        .{
            .name = "no sentinel (copied)",
            .tokens = &.{.{ .String = "abc" }},
            .want = @as([]u8, &no_sentinel),
        },
        .{
            .name = "no sentinel, const (borrowed)",
            .tokens = &.{.{ .String = "abc" }},
            .want = @as([]const u8, &no_sentinel),
        },
        .{
            .name = "sentinel (input has a sentinel)",
            .tokens = &.{.{ .StringZ = "abc" }},
            .want = @as([:0]const u8, &sentinel),
        },
        .{
            .name = "sentinel, const (input has no sentinel)",
            .tokens = &.{.{ .String = "abc" }},
            .want = @as([:0]const u8, &sentinel),
        },
        .{
            .name = "sentinel (input has no sentinel, const -> mut)",
            .tokens = &.{.{ .String = "abc" }},
            .want = @as([:0]u8, &sentinel),
        },
        // TODO: Add test case for []u8 input to []const u8 output with and without sentinel.
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try require.equal(t.want, result.value);
    }
}
