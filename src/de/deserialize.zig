const std = @import("std");
const expectEqual = std.testing.expectEqual;

const attributes = @import("../attributes.zig");
const blocks = @import("blocks.zig");
const find_db = @import("find.zig").find_db;
const Ignored = @import("impls/seed/ignored.zig").Ignored;
const t = @import("testing.zig");
const Visitor = @import("interfaces/visitor.zig").Visitor;

/// Deserializes into a value of type `T` from a `getty.Deserializer`.
pub fn deserialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// The type of the value to deserialize into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
) @TypeOf(deserializer).Error!T {
    const db = comptime find_db(T, @TypeOf(deserializer));

    if (comptime attributes.has_attributes(T, db)) {
        switch (@typeInfo(T)) {
            .Enum => {
                var v = blocks.Enum.Visitor(T){};
                return try blocks.Enum.deserialize(allocator, T, deserializer, v.visitor());
            },
            .Struct => {
                var v = blocks.Struct.Visitor(T){};
                return try blocks.Struct.deserialize(allocator, T, deserializer, v.visitor());
            },
            .Union => {
                var v = blocks.Union.Visitor(T){};
                return try blocks.Union.deserialize(allocator, T, deserializer, v.visitor());
            },
            else => unreachable, // UNREACHABLE: has_attributes guarantees that T is an enum, struct or union.
        }
    }

    var v = db.Visitor(T){};
    return try db.deserialize(allocator, T, deserializer, v.visitor());
}

fn PointVisitor(comptime Value: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace Visitor(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        fn visitSeq(
            _: Self,
            allocator: ?std.mem.Allocator,
            comptime De: type,
            seq: anytype,
        ) De.Error!Value {
            var point: Value = undefined;

            inline for (std.meta.fields(Value)) |field| {
                if (try seq.nextElement(allocator, i32)) |elem| {
                    @field(point, field.name) = elem;
                } else {
                    return error.InvalidLength;
                }
            }

            if ((try seq.nextElement(allocator, Ignored)) != null) {
                return error.InvalidLength;
            }

            return point;
        }
    };
}

test "deserialize - success, normal" {
    const Point = struct {
        x: i32,
        y: i32,
    };

    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub fn deserialize(a: ?std.mem.Allocator, comptime _: type, d: anytype, v: anytype) @TypeOf(d).Error!@TypeOf(v).Value {
            return try d.deserializeSeq(a, v);
        }

        pub const Visitor = PointVisitor;
    };

    const PointCustom = struct {
        x: i32,
        y: i32,

        const Self = @This();

        pub const @"getty.db" = struct {
            pub fn deserialize(a: ?std.mem.Allocator, comptime _: type, d: anytype, v: anytype) @TypeOf(d).Error!@TypeOf(v).Value {
                return try d.deserializeSeq(a, v);
            }

            pub const Visitor = PointVisitor;
        };
    };

    const expected = Point{ .x = 1, .y = 2 };
    const expected_custom = PointCustom{ .x = 1, .y = 2 };

    // Default DB
    {
        var d = t.DefaultDeserializer.init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "x" },
            .{ .I32 = 1 },
            .{ .String = "y" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // User DB
    {
        var d = t.Deserializer(block, null).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Deserializer DB
    {
        var d = t.Deserializer(null, block).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Type DB
    {
        var d = t.DefaultDeserializer.init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        const got = deserialize(null, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected_custom, got);
    }
}

test "deserialize - success, attributes" {
    const attrs = .{
        .x = .{ .rename = "FOO" },
        .y = .{ .rename = "BAR" },
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

    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub const attributes = attrs;
    };

    const expected = Point{ .x = 1, .y = 2 };
    const expected_custom = PointCustom{ .x = 1, .y = 2 };

    // User DB
    {
        var d = t.Deserializer(block, null).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Deserializer DB
    {
        var d = t.Deserializer(null, block).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Type DB
    {
        var d = t.DefaultDeserializer.init(&.{
            .{ .Struct = .{ .name = @typeName(PointCustom), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected_custom, got);
    }
}

test "deserialize - priority" {
    const attrs = .{
        .x = .{ .rename = "FOO" },
        .y = .{ .rename = "BAR" },
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

    // Deserializer DB > Default DB
    {
        const expected = Point{ .x = 1, .y = 2 };

        const deserializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == Point;
            }

            pub const attributes = attrs;
        };

        var d = t.Deserializer(null, deserializer_block).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Type DB > Deserializer DB
    {
        const expected = PointCustom{ .x = 1, .y = 2 };

        const deserializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointCustom;
            }

            pub const attributes = invalid_attrs;
        };

        var d = t.Deserializer(null, deserializer_block).init(&.{
            .{ .Struct = .{ .name = @typeName(PointCustom), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // User DB > Type DB
    {
        const expected = PointInvalidCustom{ .x = 1, .y = 2 };

        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointInvalidCustom;
            }

            pub const attributes = attrs;
        };

        var d = t.Deserializer(user_block, null).init(&.{
            .{ .Struct = .{ .name = @typeName(PointInvalidCustom), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, PointInvalidCustom, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }
}
