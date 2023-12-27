const require = @import("protest").require;
const std = @import("std");

const ArrayVisitor = @import("../impls/visitor/array.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Array;
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
    _ = T;

    return try deserializer.deserializeSeq(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return ArrayVisitor(T);
}

test "deserialize - array" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = [_]i32{},
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .I32 = 2 },
                .{ .I32 = 3 },
                .{ .SeqEnd = {} },
            },
            .want = [3]i32{ 1, 2, 3 },
        },
        .{
            .name = "nested",
            .tokens = &.{
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
            },
            .want = [3][2]i32{ .{ 1, 2 }, .{ 3, 4 }, .{ 5, 6 } },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try require.equalf(t.want, result.value, "Test case: \"{s}\"", .{t.name});
    }
}
