const std = @import("std");
const t = @import("../testing.zig");

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

        try t.run(deserialize, Visitor, &.{
            .{ .Union = {} },
            .{ .String = "foo" },
            .{ .Bool = true },
        }, T{ .foo = true });
        try t.run(deserialize, Visitor, &.{
            .{ .Union = {} },
            .{ .String = "bar" },
            .{ .Void = {} },
        }, T{ .bar = {} });
    }

    // Untagged
    {
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

            var v = Visitor(T){};
            const visitor = v.visitor();

            var d = t.DefaultDeserializer.init(tokens);
            const deserializer = d.deserializer();

            const got = deserialize(std.testing.allocator, T, deserializer, visitor) catch return error.UnexpectedTestError;
            try std.testing.expectEqual(true, got.foo);
        }

        {
            const tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Void = {} },
            };

            var v = Visitor(T){};
            const visitor = v.visitor();

            var d = t.DefaultDeserializer.init(tokens);
            const deserializer = d.deserializer();

            const got = deserialize(std.testing.allocator, T, deserializer, visitor) catch return error.UnexpectedTestError;
            try std.testing.expectEqual({}, got.bar);
        }
    }
}

test "deserialize - union, attributes (rename)" {
    // Tagged
    {
        const T = union(enum) {
            foo: bool,
            bar: void,

            pub const @"getty.db" = struct {
                pub const attributes = .{
                    .foo = .{ .rename = "FOO" },
                };
            };
        };
        const tokens = &.{
            .{ .Union = {} },
            .{ .String = "FOO" },
            .{ .Bool = true },
        };
        const expected = T{ .foo = true };

        try t.run(deserialize, Visitor, tokens, expected);
    }

    // Untagged
    {
        const T = union {
            foo: bool,
            bar: void,

            pub const @"getty.db" = struct {
                pub const attributes = .{
                    .foo = .{ .rename = "FOO" },
                    .bar = .{ .rename = "BAR" },
                };
            };
        };

        {
            const tokens = &.{
                .{ .Union = {} },
                .{ .String = "FOO" },
                .{ .Bool = true },
            };
            const expected = true;

            var v = Visitor(T){};
            const visitor = v.visitor();

            var d = t.DefaultDeserializer.init(tokens);
            const deserializer = d.deserializer();

            const got = deserialize(std.testing.allocator, T, deserializer, visitor) catch return error.UnexpectedTestError;
            try std.testing.expectEqual(expected, got.foo);
        }

        {
            const tokens = &.{
                .{ .Union = {} },
                .{ .String = "BAR" },
                .{ .Void = {} },
            };
            const expected = {};

            var v = Visitor(T){};
            const visitor = v.visitor();

            var d = t.DefaultDeserializer.init(tokens);
            const deserializer = d.deserializer();

            const got = deserialize(std.testing.allocator, T, deserializer, visitor) catch return error.UnexpectedTestError;
            try std.testing.expectEqual(expected, got.bar);
        }
    }
}

test "deserialize - union, attributes (skip)" {
    // Tagged
    {
        const T = union(enum) {
            foo: bool,
            bar: void,

            pub const @"getty.db" = struct {
                pub const attributes = .{
                    .foo = .{ .skip = true },
                };
            };
        };
        const tokens = &.{
            .{ .Union = {} },
            .{ .String = "foo" },
            .{ .Bool = true },
        };

        var v = Visitor(T){};
        const visitor = v.visitor();

        var d = t.DefaultDeserializer.init(tokens);
        const deserializer = d.deserializer();

        try std.testing.expectError(
            error.UnknownVariant,
            deserialize(std.testing.allocator, T, deserializer, visitor),
        );
    }

    // Untagged
    {
        const T = union {
            foo: bool,
            bar: void,

            pub const @"getty.db" = struct {
                pub const attributes = .{
                    .foo = .{ .skip = true },
                    .bar = .{ .skip = true },
                };
            };
        };

        var v = Visitor(T){};
        const visitor = v.visitor();

        {
            const tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Bool = true },
            };

            var d = t.DefaultDeserializer.init(tokens);
            const deserializer = d.deserializer();

            try std.testing.expectError(
                error.UnknownVariant,
                deserialize(std.testing.allocator, T, deserializer, visitor),
            );
        }

        {
            const tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Void = {} },
            };

            var d = t.DefaultDeserializer.init(tokens);
            const deserializer = d.deserializer();

            try std.testing.expectError(
                error.UnknownVariant,
                deserialize(std.testing.allocator, T, deserializer, visitor),
            );
        }
    }
}
