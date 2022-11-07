//! The default Serialization Block for optional values.

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Optional;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try if (value) |v| serializer.serializeSome(v) else serializer.serializeNull();
}
