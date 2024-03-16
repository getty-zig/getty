//! `EnumArray` is a _Serialization Block_ for `std.EnumArray`.

const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const blocks = @import("../blocks.zig");
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "enums.EnumArray");
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Err!@TypeOf(serializer).Ok {
    return try getty_serialize(ally, value.values, serializer);
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

test "serialize - std.EnumArray" {
    const Color = enum { red, yellow, blue, green, orange, violet };

    // empty
    // std.EnumIndexer, which is used internally by std.EnumArray,
    // fails to compile on an empty enum due to field access occuring
    // before checking field length.
    // {
    //     var array = std.enums.EnumArray(enum {}, u32).initFill(0);

    //     try t.run(null, serialize, array, &.{
    //         .{ .Seq = .{ .len = 0 } },
    //         .{ .SeqEnd = {} },
    //     });
    // }

    // non-empty
    {
        var array = std.enums.EnumArray(Color, u32).initFill(0);

        array.set(.red, 1);
        array.set(.blue, 2);
        array.set(.yellow, 3);
        array.set(.orange, 2);

        try t.run(null, serialize, array, &.{
            .{ .Seq = .{ .len = 6 } },
            .{ .U32 = 1 },
            .{ .U32 = 3 },
            .{ .U32 = 2 },
            .{ .U32 = 0 },
            .{ .U32 = 2 },
            .{ .U32 = 0 },
            .{ .SeqEnd = {} },
        });
    }
}
