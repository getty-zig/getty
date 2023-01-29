const std = @import("std");

const UnionVisitor = @import("../impls/visitor/union.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

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
    const Tagged = union(enum) {
        foo: void,
        bar: bool,
    };

    const Untagged = union {
        foo: void,
        bar: bool,
    };

    const tests = .{
        .{
            .name = "tagged, void variant",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = true,
            .want = Tagged{ .foo = {} },
        },
        .{
            .name = "tagged, non-void variant",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = true,
            .want = Tagged{ .bar = true },
        },
        .{
            .name = "untagged, void variant",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = false,
            .tag = "foo",
            .want = {},
        },
        .{
            .name = "untagged, non-void variant",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = false,
            .tag = "bar",
            .want = true,
        },
    };

    inline for (tests) |t| {
        try runTest(t, if (t.tagged) Tagged else Untagged);
    }
}

test "deserialize - union, attributes (rename)" {
    const Tagged = union(enum) {
        foo: void,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .rename = "FOO" },
                .bar = .{ .rename = "BAR" },
            };
        };
    };

    const Untagged = union {
        foo: void,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .rename = "FOO" },
                .bar = .{ .rename = "BAR" },
            };
        };
    };

    const tests = .{
        .{
            .name = "tagged, void variant (success)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "FOO" },
                .{ .Void = {} },
            },
            .tagged = true,
            .want = Tagged{ .foo = {} },
        },
        .{
            .name = "tagged, void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = true,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "tagged, non-void variant (success)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "BAR" },
                .{ .Bool = true },
            },
            .tagged = true,
            .want = Tagged{ .bar = true },
        },
        .{
            .name = "tagged, non-void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = true,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "untagged, void variant (success)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "FOO" },
                .{ .Void = {} },
            },
            .tagged = false,
            .tag = "foo",
            .want = {},
        },
        .{
            .name = "untagged, void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = false,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "untagged, non-void variant (success)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "BAR" },
                .{ .Bool = true },
            },
            .tagged = false,
            .tag = "bar",
            .want = true,
        },
        .{
            .name = "untagged, non-void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = false,
            .want_err = error.UnknownVariant,
        },
    };

    inline for (tests) |t| {
        try runTest(t, if (t.tagged) Tagged else Untagged);
    }
}

test "deserialize - union, attributes (skip)" {
    const Tagged = union(enum) {
        foo: void,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .skip = true },
                .bar = .{ .skip = true },
            };
        };
    };

    const Untagged = union {
        foo: void,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .skip = true },
                .bar = .{ .skip = true },
            };
        };
    };

    const tests = .{
        .{
            .name = "tagged, void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = true,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "tagged, non-void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = true,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "untagged, void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = false,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "untagged, non-void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = false,
            .want_err = error.UnknownVariant,
        },
    };

    inline for (tests) |t| {
        try runTest(t, if (t.tagged) Tagged else Untagged);
    }
}

fn runTest(t: anytype, comptime Want: type) !void {
    const Test = @TypeOf(t);

    if (@hasField(Test, "want_err")) {
        try testing.expectError(
            t.name,
            t.want_err,
            testing.deserializeErr(null, Self, Want, t.tokens),
        );
    } else {
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);

        if (t.tagged) {
            try testing.expectEqual(t.name, t.want, got);
        } else {
            try testing.expectEqual(t.name, t.want, @field(got, t.tag));
        }
    }
}
