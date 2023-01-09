const t = @import("getty/testing");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Optional;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try if (value) |v| serializer.serializeSome(v) else serializer.serializeNull();
}

test "serialize - optional" {
    try t.ser.run(@as(?i32, null), &[_]t.Token{.{ .Null = {} }});
    try t.ser.run(@as(?i32, 0), &[_]t.Token{ .{ .Some = {} }, .{ .I32 = 0 } });
}
