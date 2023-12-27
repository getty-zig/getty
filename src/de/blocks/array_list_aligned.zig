const require = @import("protest").require;
const std = @import("std");

const ArrayListVisitor = @import("../impls/visitor/array_list_aligned.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "array_list");
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
    return ArrayListVisitor(T);
}

test "deserialize - std.ArrayList" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.ArrayList(void).init(std.testing.allocator),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .I8 = 1 },
                .{ .I32 = 2 },
                .{ .I64 = 3 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.ArrayList(isize).init(std.testing.allocator);
                want.append(1) catch return error.UnexpectedTestError;
                want.append(2) catch return error.UnexpectedTestError;
                want.append(3) catch return error.UnexpectedTestError;
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        defer t.want.deinit();

        const Want = @TypeOf(t.want);

        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try require.equalf(t.want.capacity, result.value.capacity, "Test case: {s}", .{t.name});
        try require.equalf(t.want.items, result.value.items, "Test case: {s}", .{t.name});
    }
}

test "deserialize - std.ArrayList (recursive)" {
    const Child = std.ArrayList(isize);
    const Parent = std.ArrayList(Child);

    var want = Parent.init(std.testing.allocator);
    var a = Child.init(std.testing.allocator);
    var b = Child.init(std.testing.allocator);
    var c = Child.init(std.testing.allocator);
    defer {
        want.deinit();
        a.deinit();
        b.deinit();
        c.deinit();
    }

    try b.append(1);
    try c.append(2);
    try c.append(3);
    try want.append(a);
    try want.append(b);
    try want.append(c);

    const tokens = &.{
        .{ .Seq = .{ .len = 3 } },
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
        .{ .Seq = .{ .len = 1 } },
        .{ .I32 = 1 },
        .{ .SeqEnd = {} },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
        .{ .SeqEnd = {} },
    };

    var result = try testing.deserialize(null, Self, Parent, tokens);
    defer result.deinit();

    try require.equal(want.capacity, result.value.capacity);
    for (result.value.items, 0..) |l, i| {
        try require.equal(want.items[i].capacity, l.capacity);
        try require.equal(want.items[i].items, l.items);
    }
}
