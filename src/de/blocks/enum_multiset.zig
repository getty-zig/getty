const std = @import("std");

const EnumMultisetVisitor = @import("../impls/visitor/enum_multiset.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    const is_bounded_enum_multiset = comptime std.mem.startsWith(u8, @typeName(T), "enums.BoundedEnumMultiset");
    const is_enum_multiset = comptime std.mem.startsWith(u8, @typeName(T), "enums.EnumMultiset");

    return is_bounded_enum_multiset or is_enum_multiset;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// A memory allocator for heap values that are part of the returned
    /// deserialized value.
    result_ally: std.mem.Allocator,
    /// A memory allocator for heap values that are not part of the returned
    /// deserialized value.
    scratch_ally: std.mem.Allocator,
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
    return EnumMultisetVisitor(T);
}

const Color = enum { red, blue, yellow };

test "deserialize - std.BoundedEnumMultiset" {
    const tests = .{
        .{
            .name = "zero count",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.BoundedEnumMultiset(Color, u8).initEmpty(),
        },
        .{
            .name = "full count",
            .tokens = &.{
                .{ .Seq = .{ .len = 9 } },
                .{ .String = "red" },
                .{ .String = "blue" },
                .{ .String = "yellow" },
                .{ .String = "red" },
                .{ .String = "blue" },
                .{ .String = "yellow" },
                .{ .String = "red" },
                .{ .String = "blue" },
                .{ .String = "yellow" },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.BoundedEnumMultiset(Color, u2).initWithCount(3),
        },
        .{
            .name = "mixed count",
            .tokens = &.{
                .{ .Seq = .{ .len = 7 } },
                .{ .U8 = 0 },
                .{ .U8 = 0 },
                .{ .U8 = 1 },
                .{ .U8 = 1 },
                .{ .U8 = 1 },
                .{ .U8 = 1 },
                .{ .U8 = 2 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.enums.BoundedEnumMultiset(Color, u4).initEmpty();
                want.addAssertSafe(.red, 2);
                want.addAssertSafe(.blue, 4);
                want.addAssertSafe(.yellow, 1);
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.count(), result.value.count());
        try testing.expect(t.name, t.want.eql(result.value));
    }
}

test "deserialize - std.EnumMultiSet" {
    const tests = .{
        .{
            .name = "zero count",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.EnumMultiset(Color).initEmpty(),
        },
        .{
            .name = "uniform count",
            .tokens = &.{
                .{ .Seq = .{ .len = 12 } },
                .{ .String = "red" },
                .{ .String = "blue" },
                .{ .String = "yellow" },
                .{ .String = "red" },
                .{ .String = "blue" },
                .{ .String = "yellow" },
                .{ .String = "red" },
                .{ .String = "blue" },
                .{ .String = "yellow" },
                .{ .String = "red" },
                .{ .String = "blue" },
                .{ .String = "yellow" },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.EnumMultiset(Color).initWithCount(4),
        },
        .{
            .name = "mixed count",
            .tokens = &.{
                .{ .Seq = .{ .len = 9 } },
                .{ .U8 = 0 },
                .{ .U8 = 0 },
                .{ .U8 = 1 },
                .{ .U8 = 1 },
                .{ .U8 = 1 },
                .{ .U8 = 1 },
                .{ .U8 = 0 },
                .{ .U8 = 2 },
                .{ .U8 = 2 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.enums.EnumMultiset(Color).initEmpty();
                want.addAssertSafe(.red, 3);
                want.addAssertSafe(.blue, 4);
                want.addAssertSafe(.yellow, 2);
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.count(), result.value.count());
        try testing.expect(t.name, t.want.eql(result.value));
    }
}
