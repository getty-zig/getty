const std = @import("std");
const t = @import("../testing.zig");

const BoundedArrayVisitor = @import("../impls/visitor/bounded_array.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "bounded_array");
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
    _ = T;

    return try deserializer.deserializeSeq(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return BoundedArrayVisitor(T);
}

test "deserialize - bounded array" {
    {
        var expected = try std.BoundedArray(i32, 0).init(0);

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        var expected = try std.BoundedArray(i32, 3).init(0);

        try expected.append(1);
        try expected.append(2);
        try expected.append(3);

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        const Child = std.BoundedArray(i32, 2);
        const Parent = std.BoundedArray(Child, 3);

        var expected = try Parent.init(0);
        var a = try Child.init(0);
        var b = try Child.init(0);
        var c = try Child.init(0);

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try expected.append(a);
        try expected.append(b);
        try expected.append(c);

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

        // Test manually since the `t` function cannot recursively test
        // user-defined containers containers without ugly hacks.
        var v = Visitor(Parent){};
        const visitor = v.visitor();

        var d = t.DefaultDeserializer.init(tokens);
        const deserializer = d.deserializer();

        const got = deserialize(std.testing.allocator, Parent, deserializer, visitor) catch return error.UnexpectedTestError;

        try std.testing.expectEqual(expected.capacity(), got.capacity());
        for (got.slice()) |l, i| {
            try std.testing.expectEqual(expected.get(i).capacity(), l.capacity());
            try std.testing.expectEqualSlices(i32, expected.get(i).slice(), l.slice());
        }
    }
}
