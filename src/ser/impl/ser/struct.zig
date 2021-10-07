const getty = @import("../../../lib.zig");
const std = @import("std");

pub usingnamespace getty.Ser(
    *@This(),
    serialize,
);

fn serialize(_: *@This(), value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const st = (try serializer.serializeStruct(@typeName(T), std.meta.fields(T).len)).structSerialize();
    inline for (@typeInfo(T).Struct.fields) |field| {
        if (field.field_type != void) {
            try st.serializeField(field.name, @field(value, field.name));
        }
    }
    return try st.end();
}
