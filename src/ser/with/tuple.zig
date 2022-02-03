const std = @import("std");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Struct and @typeInfo(T).Struct.is_tuple;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const tuple = (try serializer.serializeTuple(std.meta.fields(T).len)).tuple();
    inline for (@typeInfo(T).Struct.fields) |field| {
        try tuple.serializeElement(@field(value, field.name));
    }
    return try tuple.end();
}
