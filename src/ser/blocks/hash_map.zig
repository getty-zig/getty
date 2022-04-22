const std = @import("std");

pub fn is(comptime T: type) bool {
    return std.mem.startsWith(u8, @typeName(T), "std.hash_map");
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const m = (try serializer.serializeMap(value.count())).map();
    {
        var iterator = value.iterator();
        while (iterator.next()) |entry| {
            try m.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return try m.end();
}
