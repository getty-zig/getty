const std = @import("std");
const t = @import("getty/testing");

const de = @import("../de.zig");

const PointerVisitor = @import("../impls/visitor/pointer.zig").Visitor;

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
    const db = de.de.find_db(@TypeOf(deserializer), Child);

    return try db.deserialize(allocator, Child, deserializer, visitor);
}

test "deserialize - pointer" {
    // one level of indirection
    {
        const int: i32 = 1;

        try t.de.run(deserialize, Visitor, &.{.{ .I32 = 1 }}, &int);
    }

    // two level of indirection
    {
        const free = @import("../de.zig").de.free;

        const Expected = **i32;
        const expected: i32 = 1;

        // Test manually since the `t` function cannot recursively test
        // pointers without ugly hacks.
        var v = Visitor(Expected){};
        const visitor = v.visitor();

        var d = t.de.DefaultDeserializer.init(&.{.{ .I32 = 1 }});
        const deserializer = d.deserializer();

        const got = deserialize(std.testing.allocator, Expected, deserializer, visitor) catch return error.UnexpectedTestError;
        defer free(std.testing.allocator, got);

        try std.testing.expectEqual(Expected, @TypeOf(got));
        try std.testing.expectEqual(*i32, @TypeOf(got.*));
        try std.testing.expectEqual(i32, @TypeOf(got.*.*));
        try std.testing.expectEqual(expected, got.*.*);
    }
}

test "deserialize - pointer, string" {
    // No sentinel
    {
        // *[N]u8
        {
            var arr = [3]u8{ 'a', 'b', 'c' };

            try t.de.run(deserialize, Visitor, &.{.{ .String = "abc" }}, &arr);
            try t.de.run(deserialize, Visitor, &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            }, &arr);
        }

        // *const [N]u8
        {
            const arr = [3]u8{ 'a', 'b', 'c' };

            try t.de.run(deserialize, Visitor, &.{.{ .String = "abc" }}, &arr);
            try t.de.run(deserialize, Visitor, &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            }, &arr);
        }
    }

    // Sentinel
    {
        // *[N:S]u8
        {
            var arr = [3:0]u8{ 'a', 'b', 'c' };

            try t.de.run(deserialize, Visitor, &.{.{ .String = "abc" }}, &arr);
            try t.de.run(deserialize, Visitor, &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            }, &arr);
        }

        // *const [N:S]u8
        {
            const arr = [3:0]u8{ 'a', 'b', 'c' };

            try t.de.run(deserialize, Visitor, &.{.{ .String = "abc" }}, &arr);
            try t.de.run(deserialize, Visitor, &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            }, &arr);
        }
    }
}
