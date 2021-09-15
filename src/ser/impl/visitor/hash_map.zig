const Visitor = @import("../../interface.zig").Visitor;

const HashMapVisitor = @This();

pub usingnamespace Visitor(
    *HashMapVisitor,
    serialize,
);

fn serialize(_: *HashMapVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const st = (try serializer.serializeMap(value.count())).mapSerialize();
    {
        var iterator = value.iterator();
        while (iterator.next()) |entry| {
            try st.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return try st.end();
}
