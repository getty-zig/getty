const std = @import("std");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Struct and @typeInfo(T).Struct.is_tuple;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const seq = (try serializer.serializeSeq(std.meta.fields(T).len)).seq();
    inline for (@typeInfo(T).Struct.fields) |field| {
        try seq.serializeElement(@field(value, field.name));
    }
    return try seq.end();
}
