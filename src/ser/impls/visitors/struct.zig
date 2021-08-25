const meta = @import("std").meta;
const getty = @import("../../../lib.zig");

const StructVisitor = @This();

pub fn visitor(self: *StructVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *StructVisitor,
    serialize,
);

fn serialize(_: *StructVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const st = (try serializer.serializeStruct(@typeName(T), meta.fields(T).len)).structure();
    inline for (@typeInfo(T).Struct.fields) |field| {
        try st.serializeField(field.name, @field(value, field.name));
    }
    return try st.end();
}
