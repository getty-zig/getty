const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const blocks = @import("../blocks.zig");
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    const is_bounded_enum_multiset = comptime std.mem.startsWith(u8, @typeName(T), "enums.BoundedEnumMultiset");
    const is_enum_multiset = comptime std.mem.startsWith(u8, @typeName(T), "enums.EnumMultiset");

    return is_bounded_enum_multiset or is_enum_multiset;
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
    _ = ally;
    const K = std.meta.FieldType(@TypeOf(value), .counts).Key;
    const fields = std.meta.fields(K);

    // Store the keys contained in the multiset so we don't need to find them again.
    var keys: [fields.len]K = undefined;
    // Count the number of non-zero entries.
    var count: usize = 0;
    inline for (fields) |field| {
        const key = @as(K, @enumFromInt(field.value));
        if (value.contains(key)) {
            keys[count] = key;
            count += 1;
        }
    }

    var m = try serializer.serializeMap(count);
    const map = m.map();

    for (keys[0..count]) |key| {
        try map.serializeEntry(key, value.getCount(key));
    }

    return try map.end();
}

const Color = enum { red, blue, yellow, green, orange, violet };

test "serialize - std.BoundedEnumMultiset" {
    var multiset = std.enums.BoundedEnumMultiset(Color, u8).initEmpty();

    try t.run(null, serialize, multiset, &.{
        .{ .Map = .{ .len = 0 } },
        .{ .MapEnd = {} },
    });

    try multiset.add(.red, 1);
    try multiset.add(.blue, 2);
    try multiset.add(.yellow, 3);
    try multiset.add(.orange, 2);

    try t.run(null, serialize, multiset, &.{
        .{ .Map = .{ .len = 4 } },
        .{ .Enum = {} },
        .{ .String = "red" },
        .{ .U8 = 1 },
        .{ .Enum = {} },
        .{ .String = "blue" },
        .{ .U8 = 2 },
        .{ .Enum = {} },
        .{ .String = "yellow" },
        .{ .U8 = 3 },
        .{ .Enum = {} },
        .{ .String = "orange" },
        .{ .U8 = 2 },
        .{ .MapEnd = {} },
    });
}

test "serialize - std.EnumMultiset" {
    var multiset = std.enums.EnumMultiset(Color).initEmpty();

    try t.run(null, serialize, multiset, &.{
        .{ .Map = .{ .len = 0 } },
        .{ .MapEnd = {} },
    });

    try multiset.add(.red, 1);
    try multiset.add(.blue, 2);
    try multiset.add(.yellow, 4);
    try multiset.add(.violet, 3);

    try t.run(null, serialize, multiset, &.{
        .{ .Map = .{ .len = 4 } },
        .{ .Enum = {} },
        .{ .String = "red" },
        .{ .U64 = 1 },
        .{ .Enum = {} },
        .{ .String = "blue" },
        .{ .U64 = 2 },
        .{ .Enum = {} },
        .{ .String = "yellow" },
        .{ .U64 = 4 },
        .{ .Enum = {} },
        .{ .String = "violet" },
        .{ .U64 = 3 },
        .{ .MapEnd = {} },
    });
}
