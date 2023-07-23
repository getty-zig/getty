const std = @import("std");
const expectEqual = std.testing.expectEqual;

const dt = @import("tuples.zig").dt;
const has_attributes = @import("../attributes.zig").has_attributes;
const has_block = @import("../block.zig").has_block;
const t = @import("testing.zig");

/// Returns deserialization attributes for `T`. If none exist, `null` is returned.
pub fn getAttributes(
    /// The type for which attributes should be returned.
    comptime T: type,
    /// A `getty.Deserializer` interface type.
    comptime D: type,
) blk: {
    // Process user DBs.
    for (D.user_dt) |db| {
        if (db.is(T) and has_attributes(T, db)) {
            break :blk ?@TypeOf(db.attributes);
        }
    }

    // Process type DBs.
    if (has_block(T, .de)) {
        const db = T.@"getty.db";

        if (has_attributes(T, db)) {
            break :blk ?@TypeOf(db.attributes);
        }
    }

    // Process deserializer DBs.
    for (D.deserializer_dt) |db| {
        if (db.is(T) and has_attributes(T, db)) {
            break :blk ?@TypeOf(db.attributes);
        }
    }

    break :blk ?void;
} {
    comptime {
        // Process user DBs.
        for (D.user_dt) |db| {
            if (db.is(T) and has_attributes(T, db)) {
                return @as(?@TypeOf(db.attributes), db.attributes);
            }
        }

        // Process type DBs.
        if (has_block(T, .de)) {
            const db = T.@"getty.db";

            if (has_attributes(T, db)) {
                return @as(?@TypeOf(db.attributes), db.attributes);
            }
        }

        // Process deserializer DBs.
        for (D.deserializer_dt) |db| {
            if (db.is(T) and has_attributes(T, db)) {
                return @as(?@TypeOf(db.attributes), db.attributes);
            }
        }

        return null;
    }
}

test "getAttributes - fail" {
    const De = t.DefaultDeserializer.@"getty.Deserializer";

    const expected: ?void = null;

    try expectEqual(expected, comptime getAttributes(bool, De));
    try expectEqual(expected, comptime getAttributes(i32, De));
    try expectEqual(expected, comptime getAttributes([5]i32, De));
    try expectEqual(expected, comptime getAttributes(struct {}, De));
    try expectEqual(expected, comptime getAttributes(union(enum) { foo, bar }, De));
    try expectEqual(expected, comptime getAttributes(std.meta.Tuple(&.{ struct {}, union(enum) { foo, bar } }), De));
    try expectEqual(expected, comptime getAttributes(struct {
        pub fn is(comptime _: bool) type {
            return true;
        }

        pub const attributes = .{}; // empty attribute list
    }, De));

    inline for (dt) |block| {
        try expectEqual(expected, comptime getAttributes(block, De));
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

    // User DB
    {
        const D = t.Deserializer(block, null);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, comptime getAttributes(Point, De));
    }

    // Deserializer DB
    {
        const D = t.Deserializer(null, block);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, comptime getAttributes(Point, De));
    }

    // Type DB
    {
        const De = t.DefaultDeserializer.@"getty.Deserializer";

        const PointCustom = struct {
            x: i32,
            y: i32,

            pub const @"getty.db" = struct {
                pub const attributes = attrs;
            };
        };

        try expectEqual(expected, comptime getAttributes(PointCustom, De));
    }
}

test "getAttributes - priority" {
    const attrs = .{
        .x = .{ .rename = "X" },
        .y = .{ .skip = true },
    };
    const invalid_attrs = .{
        .foo = .{ .bar = "TESTING" },
    };

    const Point = struct {
        x: i32,
        y: i32,
    };
    const PointCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.db" = struct {
            pub const attributes = attrs;
        };
    };
    const PointInvalidCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.db" = struct {
            pub const attributes = invalid_attrs;
        };
    };

    const expected: ?@TypeOf(attrs) = attrs;

    // User DB > Type DB
    {
        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointInvalidCustom;
            }

            pub const attributes = attrs;
        };

        const D = t.Deserializer(user_block, null);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, comptime getAttributes(PointInvalidCustom, De));
    }

    // User DB > Deserializer DB
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

            pub const attributes = invalid_attrs;
        };

        const D = t.Deserializer(user_block, serializer_block);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, comptime getAttributes(Point, De));
    }

    // Type DB > Deserializer DB
    {
        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointCustom;
            }

            pub const attributes = invalid_attrs;
        };

        const D = t.Deserializer(null, serializer_block);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, comptime getAttributes(PointCustom, De));
    }
}
