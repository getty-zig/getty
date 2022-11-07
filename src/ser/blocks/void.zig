//! The default Serialization Block for void values.

pub fn is(comptime T: type) bool {
    return T == void;
}

pub fn serialize(_: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeVoid();
}
