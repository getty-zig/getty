const t = @import("getty/testing");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Int, .ComptimeInt => true,
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
    return try serializer.serializeInt(value);
}

test "serialize - integer" {
    // comptime_int
    try t.ser.run(serialize, 0, &[_]t.Token{.{ .ComptimeInt = {} }});

    // signed
    try t.ser.run(serialize, @as(i8, 0), &[_]t.Token{.{ .I8 = 0 }});
    try t.ser.run(serialize, @as(i16, 0), &[_]t.Token{.{ .I16 = 0 }});
    try t.ser.run(serialize, @as(i32, 0), &[_]t.Token{.{ .I32 = 0 }});
    try t.ser.run(serialize, @as(i64, 0), &[_]t.Token{.{ .I64 = 0 }});
    try t.ser.run(serialize, @as(i128, 0), &[_]t.Token{.{ .I128 = 0 }});

    // unsigned
    try t.ser.run(serialize, @as(u8, 0), &[_]t.Token{.{ .U8 = 0 }});
    try t.ser.run(serialize, @as(u16, 0), &[_]t.Token{.{ .U16 = 0 }});
    try t.ser.run(serialize, @as(u32, 0), &[_]t.Token{.{ .U32 = 0 }});
    try t.ser.run(serialize, @as(u64, 0), &[_]t.Token{.{ .U64 = 0 }});
    try t.ser.run(serialize, @as(u128, 0), &[_]t.Token{.{ .U128 = 0 }});
}
