const std = @import("std");

const blocks = @import("../blocks.zig");
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    const is_int_bitset = comptime std.mem.startsWith(u8, @typeName(T), "bit_set.IntegerBitSet");
    const is_array_bitset = comptime std.mem.startsWith(u8, @typeName(T), "bit_set.ArrayBitSet");

    return is_int_bitset or is_array_bitset;
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
    const T = @TypeOf(value);

    const is_int_bitset = comptime std.mem.startsWith(u8, @typeName(T), "bit_set.IntegerBitSet");
    const is_array_bitset = comptime std.mem.startsWith(u8, @typeName(T), "bit_set.ArrayBitSet");

    if (is_int_bitset) {
        return try blocks.IntegerBitSet.serialize(ally, value, serializer);
    } else if (is_array_bitset) {
        return try blocks.ArrayBitSet.serialize(ally, value, serializer);
    } else {
        // UNREACHABLE: The is function should guarantee that only
        // std.IntegerBitSet or std.ArrayBitSet values are passed to this
        // function.
        unreachable;
    }
}
