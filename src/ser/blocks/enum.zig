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
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = ally;

    const T = @TypeOf(value);
    const is_literal = @typeInfo(T) == .EnumLiteral;

    var name = @tagName(value);
    const index = if (is_literal) 0 else @intFromEnum(value);

    // Process attributes.
    //
    // Only non-literal enums can define attributes (and have type
    // information), hence why this if statement is here.
    if (!is_literal) {
        const fields = std.meta.fields(T);
        const attributes = comptime getAttributes(T, @TypeOf(serializer));

        if (attributes) |attrs| {
            inline for (fields) |field| {
                const tag_matches = value == @field(T, field.name);

                if (tag_matches) {
                    const attrs_exist = @hasField(@TypeOf(attrs), field.name);

                    if (attrs_exist) {
                        const attr = @field(attrs, field.name);

                        const skipped = @hasField(@TypeOf(attr), "skip") and attr.skip;
                        if (skipped) return error.UnknownVariant;

                        const renamed = @hasField(@TypeOf(attr), "rename");
                        if (renamed) name = attr.rename;

                        break;
                    }
                }
            }
        }
    }

    return try serializer.serializeEnum(index, name);
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
