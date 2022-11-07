const std = @import("std");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Union;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);
    const info = @typeInfo(T).Union;

    if (info.tag_type == null) {
        @compileError("type `" ++ @typeName(T) ++ "`" ++ "is not supported");
    }

    var m = try serializer.serializeMap(1);
    const map = m.map();
    inline for (info.fields) |field| {
        if (std.mem.eql(u8, field.name, @tagName(value))) {
            try map.serializeEntry(field.name, @field(value, field.name));
        }
    }
    return try map.end();
}
