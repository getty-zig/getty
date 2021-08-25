const ser = @import("../../../lib.zig").ser;

const StringHashMapVisitor = @This();

pub fn visitor(self: *StringHashMapVisitor) V {
    return .{ .context = self };
}

const V = ser.Visitor(
    *StringHashMapVisitor,
    serialize,
);

fn serialize(_: *StringHashMapVisitor, serializer: anytype, input: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const st = (try serializer.serializeMap(input.count())).map();
    {
        var iterator = input.iterator();
        while (iterator.next()) |entry| {
            try st.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return try st.end();
}
