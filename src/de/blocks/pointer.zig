const std = @import("std");

const find_db = @import("../find.zig").find_db;
const free = @import("../free.zig").free;
const PointerVisitor = @import("../impls/visitor/pointer.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return PointerVisitor(T);
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
    const Child = std.meta.Child(T);
    const db = find_db(Child, @TypeOf(deserializer));

    return try db.deserialize(allocator, Child, deserializer, visitor);
}

test "deserialize - pointer" {
    var want: i32 = 1;

    const tests = .{
        .{
            .name = "one level of indirection",
            .tokens = &.{.{ .I32 = 1 }},
            .want = @as(*i32, &want),
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, &.{.{ .I32 = 1 }});
        defer free(std.testing.allocator, got);

        try testing.expectEqual(t.name, t.want.*, got.*);
    }
}

test "deserialize - pointer, string" {
    var no_sentinel = [3]u8{ 'a', 'b', 'c' };
    const no_sentinel_const = [3]u8{ 'a', 'b', 'c' };

    var sentinel = [3:0]u8{ 'a', 'b', 'c' };
    const sentinel_const = [3:0]u8{ 'a', 'b', 'c' };

    const tests = .{
        .{
            .name = "no sentinel (string)",
            .tokens = &.{.{ .String = "abc" }},
            .want = &no_sentinel,
        },
        .{
            .name = "no sentinel (sequence)",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            },
            .want = &no_sentinel,
        },
        .{
            .name = "no sentinel, const (string)",
            .tokens = &.{.{ .String = "abc" }},
            .want = &no_sentinel_const,
        },
        .{
            .name = "no sentinel, const (sequence)",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            },
            .want = &no_sentinel_const,
        },
        .{
            .name = "sentinel (string)",
            .tokens = &.{.{ .String = "abc" }},
            .want = &sentinel,
        },
        .{
            .name = "sentinel (sequence)",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            },
            .want = &sentinel,
        },
        .{
            .name = "sentinel, const (string)",
            .tokens = &.{.{ .String = "abc" }},
            .want = &sentinel_const,
        },
        .{
            .name = "sentinel, const (sequence)",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            },
            .want = &sentinel_const,
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, got);

        try testing.expectEqualStrings(t.name, t.want, got);
    }
}

test "deserialize - pointer (recursive)" {
    const Want = **i32;
    const want: i32 = 1;

    const got = try testing.deserialize(std.testing.allocator, null, Self, Want, &.{.{ .I32 = 1 }});
    defer free(std.testing.allocator, got);

    try std.testing.expectEqual(Want, @TypeOf(got));
    try std.testing.expectEqual(*i32, @TypeOf(got.*));
    try std.testing.expectEqual(i32, @TypeOf(got.*.*));
    try std.testing.expectEqual(want, got.*.*);
}
