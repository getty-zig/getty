//! The default Serialization Block for array values.

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Array;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    var s = try serializer.serializeSeq(value.len);
    const seq = s.seq();
    for (value) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}
