const std = @import("std");

const getAttributes = @import("../attributes.zig").getAttributes;
const getty_serialize = @import("../serialize.zig").serialize;
const t = @import("../testing.zig");
const Tag = @import("../../attributes.zig").Tag;

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Union;
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
    const T = @TypeOf(value);
    const info = @typeInfo(T).Union;

    if (info.tag_type == null) {
        @compileError(std.fmt.comptimePrint("untagged unions cannot be serialized: {s}", .{@typeName(T)}));
    }

    // We cannot use @tagName to set the comptime name variable, which is
    // required for @field-ing into the active union variant. So, we have this
    // for loop here so that we can use the field name provided by @typeInfo
    // instead.
    inline for (info.fields) |field| {
        const tag_matches = value == @field(T, field.name);

        if (tag_matches) {
            return try serializeVariant(ally, value, serializer, field);
        }
    }

    // UNREACHABLE: We've already checked that the union has a tag, meaning
    // that the above for loop will always enter its top-level if block, which
    // always returns from this function.
    unreachable;
}

fn serializeVariant(
    ally: ?std.mem.Allocator,
    value: anytype,
    serializer: anytype,
    comptime field: std.builtin.Type.UnionField,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const tag: Tag = comptime blk: {
        const attributes = getAttributes(@TypeOf(value), @TypeOf(serializer));

        if (attributes) |attrs| {
            if (@hasField(@TypeOf(attrs), "Container")) {
                if (@hasField(@TypeOf(attrs.Container), "tag")) {
                    break :blk attrs.Container.tag;
                }
            }
        }

        break :blk .external;
    };

    return switch (tag) {
        .external => try serializeExternallyTaggedVariant(value, serializer, field),
        .untagged => try serializeUntaggedVariant(ally, value, serializer, field),
        .internal => @compileError("TODO: internally tagged representation"),
    };
}

fn serializeExternallyTaggedVariant(
    value: anytype,
    serializer: anytype,
    comptime field: std.builtin.Type.UnionField,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const attrs = comptime blk: {
        const attributes = getAttributes(@TypeOf(value), @TypeOf(serializer));

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
        const skipped = @hasField(@TypeOf(a), "skip") and a.skip;
        if (skipped) return error.UnknownVariant;
    }

    var m = try serializer.serializeMap(1);
    const map = m.map();

    comptime var name = field.name;

    if (attrs) |a| {
        const renamed = @hasField(@TypeOf(a), "rename");
        if (renamed) name = a.rename;
    }

    try map.serializeEntry(name, @field(value, field.name));

    return try map.end();
}

fn serializeUntaggedVariant(
    ally: ?std.mem.Allocator,
    value: anytype,
    serializer: anytype,
    comptime field: std.builtin.Type.UnionField,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return getty_serialize(ally, @field(value, field.name), serializer);
}

test "serialize - union" {
    const T = union(enum) {
        Int: i32,
        Bool: bool,
    };

    try t.run(null, serialize, T{ .Int = 0 }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Int" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
    try t.run(null, serialize, T{ .Bool = true }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Bool" },
        .{ .Bool = true },
        .{ .MapEnd = {} },
    });
}

test "serialize - union, attributes (rename)" {
    const T = union(enum) {
        Int: i32,
        Bool: bool,

        pub const @"getty.sb" = struct {
            pub const attributes = .{
                .Int = .{ .rename = "Bool" },
                .Bool = .{ .rename = "Int" },
            };
        };
    };

    try t.run(null, serialize, T{ .Int = 0 }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Bool" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
    try t.run(null, serialize, T{ .Bool = true }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Int" },
        .{ .Bool = true },
        .{ .MapEnd = {} },
    });
}

test "serialize - union, attributes (skip)" {
    const T = union(enum) {
        Int: i32,
        Bool: bool,

        pub const @"getty.sb" = struct {
            pub const attributes = .{
                .Int = .{ .skip = true },
            };
        };
    };

    try t.runErr(null, serialize, error.UnknownVariant, T{ .Int = 0 }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Int" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
}

test "serialize - union, attributes (tag, untagged)" {
    const T = union(enum) {
        Int: i32,
        Bool: bool,
        Union: union(enum) {
            Int: i32,
            Bool: bool,
        },

        pub const @"getty.sb" = struct {
            pub const attributes = .{
                .Container = .{ .tag = .untagged },
            };
        };
    };

    try t.run(null, serialize, T{ .Int = 0 }, &.{.{ .I32 = 0 }});
    try t.run(null, serialize, T{ .Bool = true }, &.{.{ .Bool = true }});
    try t.run(null, serialize, T{ .Union = .{ .Int = 0 } }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Int" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
    try t.run(null, serialize, T{ .Union = .{ .Bool = true } }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Bool" },
        .{ .Bool = true },
        .{ .MapEnd = {} },
    });
}
