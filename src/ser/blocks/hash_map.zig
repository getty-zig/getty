//! The default Serialization Block for std.HashMap values.

const std = @import("std");

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "hash_map");
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
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
