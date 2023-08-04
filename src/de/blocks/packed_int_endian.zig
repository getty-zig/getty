const std = @import("std");

const PackedIntEndianVisitor = @import("../impls/visitor/packed_int_endian.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

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
    ally: ?std.mem.Allocator,
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
    return PackedIntEndianVisitor(T);
}

test "deserialize - std.PackedIntArray" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.PackedIntArray(i32, 0).init([0]i32{}),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .I32 = 1 },
                .{ .I32 = 1 },
                .{ .SeqEnd = {} },
            },
            .want = std.PackedIntArray(i32, 3).init([3]i32{ 1, 1, 1 }),
        },
        .{
            .name = "initAllTo",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .I32 = -1 },
                .{ .I32 = -1 },
                .{ .I32 = -1 },
                .{ .SeqEnd = {} },
            },
            .want = std.PackedIntArray(i32, 3).initAllTo(-1),
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);

        try testing.expectEqual(t.name, t.want, got);
    }
}
