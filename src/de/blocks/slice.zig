const std = @import("std");

const getty_free = @import("../free.zig").free;
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
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try switch (comptime std.meta.trait.isZigString(T)) {
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

/// Frees resources allocated by Getty during deserialization.
pub fn free(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// A `getty.Deserializer` interface type.
    comptime Deserializer: type,
    /// A value to deallocate.
    value: anytype,
) void {
    if (comptime std.meta.trait.isZigString(@TypeOf(value))) {
        ally.free(value);
    } else {
        for (value) |v| getty_free(ally, Deserializer, v);
        ally.free(value);
    }
}

test "deserialize - slice, string" {
    var no_sentinel = [_]u8{ 'a', 'b', 'c' };
    var sentinel = [_:0]u8{ 'a', 'b', 'c' };

    const tests = .{
        .{
            .name = "no sentinel (copied)",
            .tokens = &.{.{ .String = "abc" }},
            .want = @as([]u8, &no_sentinel),
            .lifetime = .stack,
        },
        .{
            .name = "no sentinel, const (direct)",
            .tokens = &.{.{ .String = "abc" }},
            .want = @as([]const u8, &no_sentinel),
            .lifetime = .heap,
        },
        .{
            .name = "sentinel (copied, input has no sentinel, const -> mut)",
            .tokens = &.{.{ .String = "abc" }},
            .want = @as([:0]u8, &sentinel),
            .lifetime = .stack,
        },
        .{
            .name = "sentinel, (copied, input has no sentinel)",
            .tokens = &.{.{ .String = "abc" }},
            .want = @as([:0]const u8, &sentinel),
            .lifetime = .stack,
        },
        .{
            .name = "sentinel (direct, input has a sentinel)",
            .tokens = &.{.{ .StringZ = "abc" }},
            .want = @as([:0]const u8, &sentinel),
            .lifetime = .heap,
        },
        // TODO: Add test case for []u8 input to []const u8 output with and without sentinel.
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserializeWithLifetime(std.testing.allocator, t.name, Self, Want, t.tokens, t.lifetime);
        defer if (t.lifetime != .heap) std.testing.allocator.free(got);

        try testing.expectEqualStrings(t.name, t.want, got);
    }
}
