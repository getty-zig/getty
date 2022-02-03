const std = @import("std");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and comptime !std.meta.trait.isZigString(T);
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const seq = (try serializer.serializeSequence(value.len)).seq();
    for (value) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}
