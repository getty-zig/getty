const getty = @import("../../../lib.zig");

pub usingnamespace getty.Ser(
    *@This(),
    serialize,
);

fn serialize(_: *@This(), value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const st = (try serializer.serializeMap(value.count())).mapSerialize();
    {
        var iterator = value.iterator();
        while (iterator.next()) |entry| {
            try st.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return try st.end();
}
