//! The default Serialization Block for bool values.

pub fn is(comptime T: type) bool {
    return T == bool;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeBool(value);
}
