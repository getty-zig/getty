const std = @import("std");

const EnumMultisetVisitor = @import("../impls/visitor/enum_multiset.zig").Visitor;
const getty_free = @import("../free.zig").free;
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
    return EnumMultisetVisitor(T);
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
    var mut = value;
    var it = mut.iterator();
    while (it.next()) |entry| {
        getty_free(ally, Deserializer, entry.value.*);
    }
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
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);

        try testing.expectEqual(t.name, t.want.count(), got.count());
        try testing.expect(t.name, t.want.eql(got));
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
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);

        try testing.expectEqual(t.name, t.want.count(), got.count());
        try testing.expect(t.name, t.want.eql(got));
    }
}
