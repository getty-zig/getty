const Visitor = @import("../../interface.zig").Visitor;

const StringHashMapVisitor = @This();

pub usingnamespace Visitor(
    *StringHashMapVisitor,
    serialize,
);

fn serialize(_: *StringHashMapVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const st = (try serializer.serializeMap(value.count())).map();
    {
        var iterator = value.iterator();
        while (iterator.next()) |entry| {
            try st.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return try st.end();
}
