const std = @import("std");

const getAttributes = @import("../attributes.zig").getAttributes;
const t = @import("../testing.zig");

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
    allocator: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = allocator;

    const T = @TypeOf(value);
    const info = @typeInfo(T).Union;
    const attributes = comptime getAttributes(T, @TypeOf(serializer));

    if (info.tag_type == null) {
        @compileError(std.fmt.comptimePrint("untagged unions cannot be serialized: {s}", .{@typeName(T)}));
    }

    // We cannot use @tagName to set the comptime name variable, which is
    // required for @field-ing into the active union variant. So, we have this
    // for loop here so that we can use the field name provided by @typeInfo
    // instead.
    inline for (info.fields) |field| {
        const tag_matches = std.meta.isTag(value, field.name);

        if (tag_matches) {
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
    }

    // UNREACHABLE: We've already checked that the union has a tag, meaning
    // that the above for loop will always enter its top-level if block, which
    // always returns from this function.
    unreachable;
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
