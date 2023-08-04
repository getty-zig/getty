const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const blocks = @import("../blocks.zig");
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    const is_indexed_set = comptime std.mem.startsWith(u8, @typeName(T), "enums.IndexedSet");
    const is_enum_set = comptime std.mem.startsWith(u8, @typeName(T), "enums.EnumSet");

    return is_indexed_set or is_enum_set;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty_serialize(ally, value.bits, serializer);
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

test "serialize - std.IndexedSet" {
    const Color = StringIndexer(&.{ "red", "yellow", "blue", "green", "orange", "violet", "indigo", "magenta" });

    // Zero-sized
    {
        var want = std.enums.IndexedSet(StringIndexer(&.{}), null).initEmpty();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });
    }

    // Empty
    {
        var want = std.enums.IndexedSet(Color, null).initEmpty();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .SeqEnd = {} },
        });
    }

    // Full
    {
        var want = std.enums.IndexedSet(Color, null).initFull();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .SeqEnd = {} },
        });
    }

    // Mixed
    {
        var want = std.enums.IndexedSet(Color, null).initMany(&.{ "yellow", "green", "violet", "magenta" });

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .SeqEnd = {} },
        });
    }
}

test "serialize - std.EnumSet" {
    const Color = enum { red, yellow, blue, green, orange, violet, indigo, magenta };

    // Zero-sized
    // std.EnumIndexer, which is used internally by std.EnumSet,
    // fails to compile on an empty enum due to field access occuring
    // before checking field length.
    // {
    //     var want = std.enums.EnumSet(enum {}).initEmpty();

    //     try t.run(null, serialize, want, &.{
    //         .{ .Seq = .{ .len = 0 } },
    //         .{ .SeqEnd = {} },
    //     });
    // }

    // Empty
    {
        var want = std.enums.EnumSet(Color).initEmpty();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .SeqEnd = {} },
        });
    }

    // Full
    {
        var want = std.enums.EnumSet(Color).initFull();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .SeqEnd = {} },
        });
    }

    // Mixed
    {
        var want = std.enums.EnumSet(Color).init(.{ .yellow = true, .green = true, .violet = true, .magenta = true });

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .SeqEnd = {} },
        });
    }
}
