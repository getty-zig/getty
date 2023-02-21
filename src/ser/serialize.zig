const std = @import("std");
const expectEqual = std.testing.expectEqual;

const blocks = @import("blocks.zig");
const default_st = @import("tuples.zig").default;
const t = @import("testing.zig");
const traits = @import("traits.zig");

/// Serializes a value into a `getty.Serializer`.
pub fn serialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// A value to serialize.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const block = comptime blk: {
        // Process user SBs.
        for (@TypeOf(serializer).user_st) |sb| {
            if (sb.is(T)) {
                break :blk sb;
            }
        }

        // Process type SBs.
        if (traits.has_sb(T)) {
            break :blk T.@"getty.sb";
        }

        // Process serializer SBs.
        for (@TypeOf(serializer).serializer_st) |sb| {
            if (sb.is(T)) {
                break :blk sb;
            }
        }

        // Process default SBs.
        inline for (default_st) |sb| {
            if (sb.is(T)) {
                break :blk sb;
            }
        }

        @compileError("type is not supported: " ++ @typeName(T));
    };

    // Process attributes, if any exist.
    if (comptime traits.has_attributes(T, block)) {
        switch (@typeInfo(T)) {
            .Enum => return try blocks.Enum.serialize(allocator, value, serializer),
            .Struct => return try blocks.Struct.serialize(allocator, value, serializer),
            .Union => return try blocks.Union.serialize(allocator, value, serializer),
            else => @compileError("unexpected type cannot be serialized using attributes"),
        }
    }

    return try block.serialize(allocator, value, serializer);
}

test "serialize - success, normal" {
    const Point = struct {
        x: i32,
        y: i32,
    };
    const PointCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.sb" = struct {
            pub fn serialize(_: ?std.mem.Allocator, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
                var s = try serializer.serializeSeq(2);
                const seq = s.seq();

                try seq.serializeElement(value.x);
                try seq.serializeElement(value.y);

                return try seq.end();
            }
        };
    };

    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub fn serialize(_: ?std.mem.Allocator, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            var s = try serializer.serializeSeq(2);
            const seq = s.seq();

            try seq.serializeElement(value.x);
            try seq.serializeElement(value.y);

            return try seq.end();
        }
    };

    const v = Point{ .x = 1, .y = 2 };
    const v_attrs = PointCustom{ .x = 1, .y = 2 };
    const expected: usize = 0;

    // Default SB
    {
        var s = t.DefaultSerializer.init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "x" },
            .{ .I32 = 1 },
            .{ .String = "y" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        serialize(null, v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // User SB
    {
        var s = t.Serializer(block, null).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        serialize(null, v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Serializer SB
    {
        var s = t.Serializer(null, block).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        serialize(null, v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Type SB
    {
        var s = t.Serializer(null, null).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        serialize(null, v_attrs, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }
}

test "serialize - success, attributes" {
    const attrs = .{
        .x = .{ .rename = "TESTING" },
        .y = .{ .skip = true },
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

    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub const attributes = attrs;
    };

    const v = Point{ .x = 1, .y = 2 };
    const v_attrs = PointCustom{ .x = 1, .y = 2 };
    const expected: usize = 0;

    // User SB
    {
        var s = t.Serializer(block, null).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(null, v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Serializer SB
    {
        var s = t.Serializer(null, block).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(null, v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Type SB
    {
        var s = t.Serializer(null, null).init(&.{
            .{ .Struct = .{ .name = @typeName(PointCustom), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(null, v_attrs, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }
}

test "serialize - priority" {
    const attrs = .{
        .x = .{ .rename = "TESTING" },
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

        pub const @"getty.sb" = struct {
            pub const attributes = attrs;
        };
    };
    const PointInvalidCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.sb" = struct {
            pub const attributes = invalid_attrs;
        };
    };

    const expected: usize = 0;

    // Serializer SB > Default SB
    {
        var v = Point{ .x = 1, .y = 2 };

        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == Point;
            }

            pub const attributes = attrs;
        };

        var s = t.Serializer(null, serializer_block).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(null, v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Type SB > Serializer SB
    {
        const v = PointCustom{ .x = 1, .y = 2 };

        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointCustom;
            }

            pub const attributes = invalid_attrs;
        };

        var s = t.Serializer(null, serializer_block).init(&.{
            .{ .Struct = .{ .name = @typeName(PointCustom), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(null, v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // User SB > Type SB
    {
        const v = PointInvalidCustom{ .x = 1, .y = 2 };

        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointInvalidCustom;
            }

            pub const attributes = attrs;
        };

        var s = t.Serializer(user_block, null).init(&.{
            .{ .Struct = .{ .name = @typeName(PointInvalidCustom), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(null, v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }
}
