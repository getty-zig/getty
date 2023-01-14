const std = @import("std");
const t = @import("getty/testing");

const UnionVisitor = @import("../impls/visitor/union.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Union;
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

    return try deserializer.deserializeUnion(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return UnionVisitor(T);
}

test "deserialize - union" {
    // Tagged
    {
        const T = union(enum) {
            foo: bool,
            bar: void,
        };

        try t.de.run(deserialize, Visitor, &.{
            .{ .Union = {} },
            .{ .String = "foo" },
            .{ .Bool = true },
        }, T{ .foo = true });
        try t.de.run(deserialize, Visitor, &.{
            .{ .Union = {} },
            .{ .String = "bar" },
            .{ .Void = {} },
        }, T{ .bar = {} });
    }

    // Untagged
    {
        const getty = @import("../../getty.zig");

        const T = union {
            foo: bool,
            bar: void,
        };

        {
            const tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Bool = true },
            };

            var d = t.de.Deserializer.init(tokens);
            const v = getty.deserialize(std.testing.allocator, T, d.deserializer()) catch return error.UnexpectedTestError;

            try std.testing.expectEqual(true, v.foo);
        }

        {
            const tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Void = {} },
            };

            var d = t.de.Deserializer.init(tokens);
            const v = getty.deserialize(std.testing.allocator, T, d.deserializer()) catch return error.UnexpectedTestError;

            try std.testing.expectEqual({}, v.bar);
        }
    }
}
