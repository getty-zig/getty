const std = @import("std");

const IndexedSetVisitor = @import("../impls/visitor/indexed_set.zig").Visitor;
const getty_free = @import("../free.zig").free;
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
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
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

/// Frees resources allocated by Getty during deserialization.
pub fn free(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// A `getty.Deserializer` interface type.
    comptime Deserializer: type,
    /// A value to deallocate.
    value: anytype,
) void {
    getty_free(ally, Deserializer, value.bits);
}

fn StringIndexer(comptime str_keys: []const []const u8) type {
    if (str_keys.len == 0) {
        return struct {
            pub const Key = []const u8;
            pub const count: usize = 0;
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
        pub const count: usize = str_keys.len;
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

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        defer free(std.testing.allocator, Deserializer, t.want);

        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        try testing.expectEqual(t.name, t.want.count(), got.count());
        try testing.expect(t.name, t.want.eql(got));
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

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        defer free(std.testing.allocator, Deserializer, t.want);

        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        try testing.expectEqual(t.name, t.want.count(), got.count());
        try testing.expect(t.name, t.want.eql(got));
    }
}
