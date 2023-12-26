const require = @import("protest").require;
const std = @import("std");

const IndexedSetVisitor = @import("../impls/visitor/indexed_set.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    const is_indexed_set = comptime std.mem.startsWith(u8, @typeName(T), "enums.IndexedSet");
    const is_enum_set = comptime std.mem.startsWith(u8, @typeName(T), "enums.EnumSEt");

    return is_indexed_set or is_enum_set;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeSeq(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return IndexedSetVisitor(T);
}

fn StringIndexer(comptime str_keys: []const []const u8) type {
    if (str_keys.len == 0) {
        return struct {
            pub const Key = []const u8;
            pub const count: comptime_int = 0;
            pub fn indexOf(k: Key) usize {
                _ = k;
                unreachable;
            }
            pub fn keyForIndex(i: usize) Key {
                _ = i;
                unreachable;
            }
        };
    }

    return struct {
        pub const Key = []const u8;
        pub const count: comptime_int = str_keys.len;
        pub fn indexOf(k: Key) usize {
            for (str_keys, 0..) |key, i| {
                if (std.mem.eql(u8, k, key)) {
                    return i;
                }
            }
            unreachable;
        }
        pub fn keyForIndex(i: usize) Key {
            return str_keys[i];
        }
    };
}

test "deserialize - std.IndexedSet" {
    const Color = StringIndexer(&.{ "red", "yellow", "blue", "green", "orange", "violet", "indigo", "magenta" });

    const tests = .{
        .{
            .name = "zero-sized",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.IndexedSet(StringIndexer(&.{}), null).initEmpty(),
        },
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.IndexedSet(Color, null).initEmpty(),
        },
        .{
            .name = "full",
            .tokens = &.{
                .{ .Seq = .{ .len = 8 } },
                .{ .String = "red" },
                .{ .String = "yellow" },
                .{ .String = "blue" },
                .{ .String = "green" },
                .{ .String = "orange" },
                .{ .String = "violet" },
                .{ .String = "indigo" },
                .{ .String = "magenta" },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.IndexedSet(Color, null).initFull(),
        },
        .{
            .name = "mixed",
            .tokens = &.{
                .{ .Seq = .{ .len = 4 } },
                .{ .String = "red" },
                .{ .String = "yellow" },
                .{ .String = "blue" },
                .{ .String = "violet" },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.IndexedSet(Color, null).initMany(&.{ "red", "yellow", "blue", "violet" }),
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try require.equal(t.want.count(), result.value.count());
        try require.isTrue(t.want.eql(result.value));
    }
}

test "deserialize - std.EnumSet" {
    const Color = enum { red, yellow, blue, green, orange, violet, indigo, magenta };

    const tests = .{
        // std.EnumIndexer, which is used internally by std.EnumSet,
        // fails to compile on an empty enum due to field access occuring
        // before checking field length.
        // .{
        //     .name = "zero-sized",
        //     .tokens = &.{
        //         .{ .Seq = .{ .len = 0 } },
        //         .{ .SeqEnd = {} },
        //     },
        //     .want = std.enums.EnumSet(enum {}){},
        // },
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.EnumSet(Color).initEmpty(),
        },
        .{
            .name = "full",
            .tokens = &.{
                .{ .Seq = .{ .len = 8 } },
                .{ .Enum = {} },
                .{ .String = "red" },
                .{ .Enum = {} },
                .{ .String = "yellow" },
                .{ .Enum = {} },
                .{ .String = "blue" },
                .{ .Enum = {} },
                .{ .String = "green" },
                .{ .Enum = {} },
                .{ .String = "orange" },
                .{ .Enum = {} },
                .{ .String = "violet" },
                .{ .Enum = {} },
                .{ .String = "indigo" },
                .{ .Enum = {} },
                .{ .String = "magenta" },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.EnumSet(Color).initFull(),
        },
        .{
            .name = "mixed",
            .tokens = &.{
                .{ .Seq = .{ .len = 4 } },
                .{ .Enum = {} },
                .{ .String = "red" },
                .{ .Enum = {} },
                .{ .String = "yellow" },
                .{ .Enum = {} },
                .{ .String = "blue" },
                .{ .Enum = {} },
                .{ .String = "violet" },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.EnumSet(Color).init(.{
                .red = true,
                .yellow = true,
                .blue = true,
                .violet = true,
            }),
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try require.equal(t.want.count(), result.value.count());
        try require.isTrue(t.want.eql(result.value));
    }
}
