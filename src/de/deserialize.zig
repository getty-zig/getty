const std = @import("std");
const expectEqual = std.testing.expectEqual;

const attributes = @import("../attributes.zig");
const blocks = @import("blocks.zig");
const find_db = @import("find.zig").find_db;
const Ignored = @import("impls/seed/ignored.zig").Ignored;
const t = @import("testing.zig");
const Visitor = @import("interfaces/visitor.zig").Visitor;

/// Deserializes data from the `getty.Deserializer` `d` into a value of type
/// `T`.
pub fn deserialize(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// The type of the value to deserialize into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    d: anytype,
) @TypeOf(d).Err!Result(T) {
    const db = comptime find_db(T, @TypeOf(d));

    var result = Result(T){
        .value = undefined,
        .arena = arena: {
            var a = try ally.create(std.heap.ArenaAllocator);
            a.* = std.heap.ArenaAllocator.init(ally);
            break :arena a;
        },
    };
    const result_ally = result.arena.allocator();
    errdefer result.deinit();

    if (comptime attributes.has_attributes(T, db)) {
        switch (@typeInfo(T)) {
            .Struct => {
                var v = blocks.Struct.Visitor(T){};
                result.value = try blocks.Struct.deserialize(result_ally, ally, T, d, v.visitor());
            },
            .Union => {
                var v = blocks.Union.Visitor(T){};
                result.value = try blocks.Union.deserialize(result_ally, ally, T, d, v.visitor());
            },
            .Enum => {
                var v = blocks.Enum.Visitor(T){};
                result.value = try blocks.Enum.deserialize(result_ally, ally, T, d, v.visitor());
            },
            // UNREACHABLE: has_attributes guarantees that T is an enum, struct
            // or union.
            else => unreachable,
        }
    } else {
        var v = db.Visitor(T){};
        result.value = try db.deserialize(result_ally, ally, T, d, v.visitor());
    }

    return result;
}

/// A managed, deserialized value.
pub fn Result(comptime T: type) type {
    return struct {
        arena: *std.heap.ArenaAllocator,
        value: T,

        pub fn deinit(self: @This()) void {
            self.arena.deinit();
            self.arena.child_allocator.destroy(self.arena);
        }
    };
}

////////////////////////////////////////////////////////////////////////////////
// TESTS
////////////////////////////////////////////////////////////////////////////////

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
            ally: std.mem.Allocator,
            comptime De: type,
            seq: anytype,
        ) De.Err!Value {
            var point: Value = undefined;

            inline for (std.meta.fields(Value)) |field| {
                if (try seq.nextElement(ally, i32)) |elem| {
                    @field(point, field.name) = elem;
                } else {
                    return error.InvalidLength;
                }
            }

            if ((try seq.nextElement(ally, Ignored)) != null) {
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

        pub fn deserialize(
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime _: type,
            d: anytype,
            v: anytype,
        ) @TypeOf(d).Err!@TypeOf(v).Value {
            return try d.deserializeSeq(result_ally, scratch_ally, v);
        }

        pub const Visitor = PointVisitor;
    };

    const PointCustom = struct {
        x: i32,
        y: i32,

        const Self = @This();

        pub const @"getty.db" = struct {
            pub fn deserialize(
                result_ally: std.mem.Allocator,
                scratch_ally: std.mem.Allocator,
                comptime _: type,
                d: anytype,
                v: anytype,
            ) @TypeOf(d).Err!@TypeOf(v).Value {
                return try d.deserializeSeq(result_ally, scratch_ally, v);
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

        var result = deserialize(std.testing.allocator, Point, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected, result.value);
    }

    // User DB
    {
        var d = t.Deserializer(block, null).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        var result = deserialize(std.testing.allocator, Point, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected, result.value);
    }

    // Deserializer DB
    {
        var d = t.Deserializer(null, block).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        var result = deserialize(std.testing.allocator, Point, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected, result.value);
    }

    // Type DB
    {
        var d = t.DefaultDeserializer.init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        var result = deserialize(std.testing.allocator, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected_custom, result.value);
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

        var result = deserialize(std.testing.allocator, Point, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected, result.value);
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

        var result = deserialize(std.testing.allocator, Point, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected, result.value);
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

        var result = deserialize(std.testing.allocator, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected_custom, result.value);
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

        var result = deserialize(std.testing.allocator, Point, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected, result.value);
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

        var result = deserialize(std.testing.allocator, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected, result.value);
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

        var result = deserialize(std.testing.allocator, PointInvalidCustom, d.deserializer()) catch return error.UnexpectedTestError;
        defer result.deinit();

        try expectEqual(expected, result.value);
    }
}
