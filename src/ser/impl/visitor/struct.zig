const Visitor = @import("../../interface.zig").Visitor;
const fields = @import("std").meta.fields;

const StructVisitor = @This();

pub usingnamespace Visitor(
    *StructVisitor,
    serialize,
);

fn serialize(_: *StructVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const st = (try serializer.serializeStruct(@typeName(T), fields(T).len)).structSerialize();
    inline for (@typeInfo(T).Struct.fields) |field| {
        if (field.field_type != void) {
            try st.serializeField(field.name, @field(value, field.name));
        }
    }
    return try st.end();
}
