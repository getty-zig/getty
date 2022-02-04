pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Array;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const seq = (try serializer.serializeSeq(value.len)).seq();
    for (value) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}
