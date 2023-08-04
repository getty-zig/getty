const std = @import("std");

const IndexedArrayVisitor = @import("../impls/visitor/indexed_array.zig").Visitor;
const getty_free = @import("../free.zig").free;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    const is_indexed_array = comptime std.mem.startsWith(u8, @typeName(T), "enums.IndexedArray");
    const is_enum_array = comptime std.mem.startsWith(u8, @typeName(T), "enums.EnumArray");

    return is_indexed_array or is_enum_array;
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
    return IndexedArrayVisitor(T);
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
    getty_free(ally, Deserializer, value.values);
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

test "deserialize - std.IndexedArray" {
    const Color = StringIndexer(&.{ "red", "yellow", "blue" });
    const Size = StringIndexer(&.{ "small", "medium", "large" });

    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.IndexedArray(StringIndexer(&.{}), u32, null).initUndefined(),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U32 = 1 },
                .{ .U32 = 3 },
                .{ .U32 = 2 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.enums.IndexedArray(Color, u32, null).initUndefined();
                want.set("red", 1);
                want.set("yellow", 3);
                want.set("blue", 2);
                break :blk want;
            },
        },
        .{
            .name = "nested",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .Seq = .{ .len = 3 } },
                .{ .U32 = 2 },
                .{ .U32 = 2 },
                .{ .U32 = 3 },
                .{ .SeqEnd = {} },
                .{ .Seq = .{ .len = 3 } },
                .{ .U32 = 0 },
                .{ .U32 = 0 },
                .{ .U32 = 0 },
                .{ .SeqEnd = {} },
                .{ .Seq = .{ .len = 3 } },
                .{ .U32 = 0 },
                .{ .U32 = 1 },
                .{ .U32 = 3 },
                .{ .SeqEnd = {} },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                const SubArray = std.enums.IndexedArray(Size, u32, null);
                const sa_1 = res: {
                    var arr = SubArray.initFill(2);
                    arr.set("large", 3);
                    break :res arr;
                };
                const sa_2 = SubArray.initFill(0);
                const sa_3 = res: {
                    var arr = SubArray.initUndefined();
                    arr.set("small", 0);
                    arr.set("medium", 1);
                    arr.set("large", 3);
                    break :res arr;
                };
                var want = std.enums.IndexedArray(Color, SubArray, null).initUndefined();
                want.set("red", sa_1);
                want.set("yellow", sa_2);
                want.set("blue", sa_3);
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);
        for (t.want.values, 0..) |want, i| {
            try testing.expectEqual(t.name, want, got.values[i]);
        }
    }
}

test "deserialize - std.EnumArray" {
    const Color = enum { red, yellow, blue };
    const Size = enum { small, medium, large };

    const tests = .{
        // std.EnumIndexer, which is used internally by std.EnumArray,
        // fails to compile on an empty enum due to field access occuring
        // before checking field length.
        // .{
        //     .name = "empty",
        //     .tokens = &.{
        //         .{ .Seq = .{ .len = 0 } },
        //         .{ .SeqEnd = {} },
        //     },
        //     .want = std.enums.EnumArray(enum {}, u32).initUndefined(),
        // },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U32 = 1 },
                .{ .U32 = 3 },
                .{ .U32 = 2 },
                .{ .SeqEnd = {} },
            },
            .want = std.enums.EnumArray(Color, u32).init(.{
                .red = 1,
                .yellow = 3,
                .blue = 2,
            }),
        },
        .{
            .name = "nested",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .Seq = .{ .len = 3 } },
                .{ .U32 = 2 },
                .{ .U32 = 2 },
                .{ .U32 = 3 },
                .{ .SeqEnd = {} },
                .{ .Seq = .{ .len = 3 } },
                .{ .U32 = 0 },
                .{ .U32 = 0 },
                .{ .U32 = 0 },
                .{ .SeqEnd = {} },
                .{ .Seq = .{ .len = 3 } },
                .{ .U32 = 0 },
                .{ .U32 = 1 },
                .{ .U32 = 3 },
                .{ .SeqEnd = {} },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                const SubArray = std.enums.EnumArray(Size, u32);
                const sa_1 = SubArray.init(.{
                    .small = 2,
                    .medium = 2,
                    .large = 3,
                });
                const sa_2 = SubArray.initFill(0);
                const sa_3 = res: {
                    var arr = SubArray.initUndefined();
                    arr.set(.small, 0);
                    arr.set(.medium, 1);
                    arr.set(.large, 3);
                    break :res arr;
                };
                var want = std.enums.EnumArray(Color, SubArray).init(.{
                    .red = sa_1,
                    .yellow = sa_2,
                    .blue = sa_3,
                });
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);
        for (t.want.values, 0..) |want, i| {
            try testing.expectEqual(t.name, want, got.values[i]);
        }
    }
}
