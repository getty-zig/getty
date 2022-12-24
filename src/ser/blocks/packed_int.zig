const std = @import("std");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    comptime {
        const is_array = std.mem.startsWith(u8, @typeName(T), "packed_int_array.PackedIntArrayEndian");
        const is_slice = std.mem.startsWith(u8, @typeName(T), "packed_int_array.PackedIntSliceEndian");

        return is_array or is_slice;
    }
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    var s = try serializer.serializeSeq(value.len);
    const seq = s.seq();

    var i: usize = 0;
    while (i < value.len) : (i += 1) {
        try seq.serializeElement(value.get(i));
    }

    return try seq.end();
}
