const std = @import("std");

const getAttributes = @import("../attributes.zig").getAttributes;
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Enum, .EnumLiteral => true,
        else => false,
    };
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = allocator;

    const T = @TypeOf(value);

    if (@typeInfo(T) == .Enum) {
        const fields = std.meta.fields(T);
        const attributes = comptime getAttributes(T, @TypeOf(serializer));

        inline for (fields) |field| {
            const attrs = comptime blk: {
                if (attributes) |attrs| {
                    if (@hasField(@TypeOf(attrs), field.name)) {
                        const a = @field(attrs, field.name);
                        const A = @TypeOf(a);

                        break :blk @as(?A, a);
                    }
                }

                break :blk null;
            };

            if (attrs) |a| {
                const matches = std.meta.isTag(value, field.name);

                const skipped = @hasField(@TypeOf(a), "skip") and a.skip;
                if (skipped and matches) return error.UnknownVariant;

                const renamed = @hasField(@TypeOf(a), "rename");
                if (renamed and matches) {
                    return try serializer.serializeEnum(value, a.rename);
                }
            }
        }
    }

    return try serializer.serializeEnum(value, @tagName(value));
}

test "serialize - enum" {
    // literal
    try t.run(null, serialize, .foo, &.{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t.run(null, serialize, .bar, &.{ .{ .Enum = {} }, .{ .String = "bar" } });

    // non-literal
    const T = enum { foo, bar };
    try t.run(null, serialize, T.foo, &.{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t.run(null, serialize, T.bar, &.{ .{ .Enum = {} }, .{ .String = "bar" } });
}

test "serialize - enum, attributes (rename)" {
    const T = enum {
        foo,
        bar,

        pub const @"getty.sb" = struct {
            pub const attributes = .{
                .foo = .{ .rename = "baz" },
                .bar = .{ .rename = "qux" },
            };
        };
    };

    try t.run(null, serialize, T.foo, &.{ .{ .Enum = {} }, .{ .String = "baz" } });
    try t.run(null, serialize, T.bar, &.{ .{ .Enum = {} }, .{ .String = "qux" } });
}

test "serialize - enum, attributes (skip)" {
    const T = enum {
        foo,
        bar,

        pub const @"getty.sb" = struct {
            pub const attributes = .{
                .foo = .{ .skip = true },
                .bar = .{ .skip = false },
            };
        };
    };

    try t.runErr(null, serialize, error.UnknownVariant, T.foo, &.{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t.run(null, serialize, T.bar, &.{ .{ .Enum = {} }, .{ .String = "bar" } });
}
