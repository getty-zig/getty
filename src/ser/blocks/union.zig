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
        if (std.mem.eql(u8, field.name, @tagName(value))) {
            // Process "skip" attribute.
            if (attributes) |attrs| {
                if (@hasField(@TypeOf(attrs), field.name)) {
                    const attr = @field(attrs, field.name);

                    if (@hasField(@TypeOf(attr), "skip") and attr.skip) {
                        return error.UnknownVariant;
                    }
                }
            }

            var m = try serializer.serializeMap(1);
            const map = m.map();

            comptime var name = field.name;

            // Process "rename" attribute.
            if (attributes) |attrs| {
                if (@hasField(@TypeOf(attrs), field.name)) {
                    const attr = @field(attrs, field.name);

                    if (@hasField(@TypeOf(attr), "rename")) {
                        name = attr.rename;
                    }
                }
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

    try t.run(serialize, T{ .Int = 0 }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Int" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
    try t.run(serialize, T{ .Bool = true }, &.{
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

    try t.run(serialize, T{ .Int = 0 }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Bool" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
    try t.run(serialize, T{ .Bool = true }, &.{
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

    try t.runErr(serialize, error.UnknownVariant, T{ .Int = 0 }, &.{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Int" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
}
