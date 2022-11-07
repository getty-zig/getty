//! The default Serialization Block for enum values.

pub fn is(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .Enum, .EnumLiteral => true,
        else => false,
    };
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeEnum(value);
}
