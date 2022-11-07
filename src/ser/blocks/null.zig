//! The default Serialization Block for null values.

pub fn is(comptime T: type) bool {
    return T == @TypeOf(null);
}

pub fn serialize(_: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeNull();
}
