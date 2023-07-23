const std = @import("std");
const expectEqual = std.testing.expectEqual;

const blocks = @import("blocks.zig");
const has_attributes = @import("../attributes.zig").has_attributes;
const has_block = @import("../block.zig").has_block;
const st = @import("tuples.zig").st;
const t = @import("testing.zig");

/// Returns attributes for `T`, given a `getty.Serializer` interface type `S`.
///
/// If no serialization attributes exist for `T`, given `S`, `null` is
/// returned.
pub fn getAttributes(
    /// The type for which attributes should be returned.
    comptime T: type,
    /// A `getty.Serializer` interface type.
    comptime S: type,
) blk: {
    // Process user SBs.
    for (S.user_st) |sb| {
        if (sb.is(T) and has_attributes(T, sb)) {
            break :blk ?@TypeOf(sb.attributes);
        }
    }

    // Process type SBs.
    if (has_block(T, .ser)) {
        const sb = T.@"getty.sb";

        if (has_attributes(T, sb)) {
            break :blk ?@TypeOf(sb.attributes);
        }
    }

    // Process user SBs.
    for (S.serializer_st) |sb| {
        if (sb.is(T) and has_attributes(T, sb)) {
            break :blk ?@TypeOf(sb.attributes);
        }
    }

    break :blk ?void;
} {
    comptime {
        // Process user SBs.
        for (S.user_st) |sb| {
            if (sb.is(T) and has_attributes(T, sb)) {
                return @as(?@TypeOf(sb.attributes), sb.attributes);
            }
        }

        // Process type SBs.
        if (has_block(T, .ser)) {
            const sb = T.@"getty.sb";

            if (has_attributes(T, sb)) {
                return @as(?@TypeOf(sb.attributes), sb.attributes);
            }
        }

        // Process serializer SBs.
        for (S.serializer_st) |sb| {
            if (sb.is(T) and has_attributes(T, sb)) {
                return @as(?@TypeOf(sb.attributes), sb.attributes);
            }
        }

        return null;
    }
}

test "getAttributes - fail" {
    const Ser = t.DefaultSerializer.@"getty.Serializer";

    const expected: ?void = null;

    try expectEqual(expected, comptime getAttributes(bool, Ser));
    try expectEqual(expected, comptime getAttributes(i32, Ser));
    try expectEqual(expected, comptime getAttributes([5]i32, Ser));
    try expectEqual(expected, comptime getAttributes(struct {}, Ser));
    try expectEqual(expected, comptime getAttributes(union(enum) { foo, bar }, Ser));
    try expectEqual(expected, comptime getAttributes(std.meta.Tuple(&.{ struct {}, union(enum) { foo, bar } }), Ser));
    try expectEqual(expected, comptime getAttributes(struct {
        pub fn is(comptime _: bool) type {
            return true;
        }

        pub const attributes = .{}; // empty attribute list
    }, Ser));

    inline for (st) |block| {
        try expectEqual(expected, comptime getAttributes(block, Ser));
    }
}

test "getAttributes - success" {
    const attrs = .{
        .x = .{ .rename = "X" },
        .y = .{ .skip = true },
    };
    const expected: ?@TypeOf(attrs) = attrs;

    const Point = struct {
        x: i32,
        y: i32,
    };
    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub const attributes = attrs;
    };

    // User SB
    {
        const S = t.Serializer(block, null);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, comptime getAttributes(Point, Ser));
    }

    // Serializer SB
    {
        const S = t.Serializer(null, block);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, comptime getAttributes(Point, Ser));
    }

    // Type SB
    {
        const Ser = t.DefaultSerializer.@"getty.Serializer";

        const PointCustom = struct {
            x: i32,
            y: i32,

            pub const @"getty.sb" = struct {
                pub const attributes = attrs;
            };
        };

        try expectEqual(expected, comptime getAttributes(PointCustom, Ser));
    }
}

test "getAttributes - priority" {
    const attrs = .{
        .x = .{ .rename = "X" },
        .y = .{ .skip = true },
    };
    const invalid_attributes = .{
        .foo = .{ .bar = "TESTING" },
    };

    const Point = struct {
        x: i32,
        y: i32,
    };
    const PointCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.sb" = struct {
            pub const attributes = attrs;
        };
    };
    const PointInvalidCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.sb" = struct {
            pub const attributes = invalid_attributes;
        };
    };

    const expected: ?@TypeOf(attrs) = attrs;

    // User SB > Type SB
    {
        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointInvalidCustom;
            }

            pub const attributes = attrs;
        };

        const S = t.Serializer(user_block, null);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, comptime getAttributes(PointInvalidCustom, Ser));
    }

    // User SB > Serializer SB
    {
        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == Point;
            }

            pub const attributes = attrs;
        };
        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == Point;
            }

            pub const attributes = invalid_attributes;
        };

        const S = t.Serializer(user_block, serializer_block);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, comptime getAttributes(Point, Ser));
    }

    // Type SB > Serializer SB
    {
        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointCustom;
            }

            pub const attributes = invalid_attributes;
        };

        const S = t.Serializer(null, serializer_block);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, comptime getAttributes(PointCustom, Ser));
    }
}
