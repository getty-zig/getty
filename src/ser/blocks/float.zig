const t = @import("getty/testing");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => true,
        else => false,
    };
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeFloat(value);
}

test "serialize - float" {
    // comptime_float
    try t.ser.run(serialize, 0.0, &[_]t.Token{.{ .ComptimeFloat = {} }});

    // float
    try t.ser.run(serialize, @as(f16, 0), &[_]t.Token{.{ .F16 = 0 }});
    try t.ser.run(serialize, @as(f32, 0), &[_]t.Token{.{ .F32 = 0 }});
    try t.ser.run(serialize, @as(f64, 0), &[_]t.Token{.{ .F64 = 0 }});
    try t.ser.run(serialize, @as(f128, 0), &[_]t.Token{.{ .F128 = 0 }});
}
