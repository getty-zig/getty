const std = @import("std");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);
    const fields = std.meta.fields(T);

    const st = (try serializer.serializeStruct(@typeName(T), fields.len)).structure();
    inline for (fields) |field| {
        if (field.field_type != void) {
            try st.serializeField(field.name, @field(value, field.name));
        }
    }
    return try st.end();
}
