const require = @import("protest").require;
const std = @import("std");

const BoundedArrayVisitor = @import("../impls/visitor/bounded_array.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "bounded_array");
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
    return BoundedArrayVisitor(T);
}

test "deserialize - std.BoundedArray" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.BoundedArray(i32, 0).init(0) catch return error.UnexpectedTestError,
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
                var want = std.BoundedArray(i32, 3).init(0) catch return error.UnexpectedTestError;
                want.append(1) catch return error.UnexpectedTestError;
                want.append(2) catch return error.UnexpectedTestError;
                want.append(3) catch return error.UnexpectedTestError;
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try require.equal(t.want, result.value);
    }
}

test "deserialize - std.BoundedArray (recursive)" {
    const Child = std.BoundedArray(i32, 2);
    const Parent = std.BoundedArray(Child, 3);

    var expected = Parent.init(0) catch return error.UnexpectedTestError;
    const a = Child.init(0) catch return error.UnexpectedTestError;
    var b = Child.init(0) catch return error.UnexpectedTestError;
    var c = Child.init(0) catch return error.UnexpectedTestError;

    b.append(1) catch return error.UnexpectedTestError;
    c.append(2) catch return error.UnexpectedTestError;
    c.append(3) catch return error.UnexpectedTestError;
    expected.append(a) catch return error.UnexpectedTestError;
    expected.append(b) catch return error.UnexpectedTestError;
    expected.append(c) catch return error.UnexpectedTestError;

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

    try require.equal(expected.capacity(), result.value.capacity());
    for (result.value.slice(), 0..) |l, i| {
        try require.equal(expected.get(i).capacity(), l.capacity());
        try require.equal(expected.get(i).slice(), l.slice());
    }
}
