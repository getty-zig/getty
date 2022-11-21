const std = @import("std");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "hash_map");
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    var m = try serializer.serializeMap(value.count());
    const map = m.map();
    {
        var iterator = value.iterator();
        while (iterator.next()) |entry| {
            try map.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return try map.end();
}
