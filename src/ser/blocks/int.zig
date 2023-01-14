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
    try t.ser.run(serialize, 0, &.{.{ .ComptimeInt = {} }});

    // signed
    try t.ser.run(serialize, @as(i8, 0), &.{.{ .I8 = 0 }});
    try t.ser.run(serialize, @as(i16, 0), &.{.{ .I16 = 0 }});
    try t.ser.run(serialize, @as(i32, 0), &.{.{ .I32 = 0 }});
    try t.ser.run(serialize, @as(i64, 0), &.{.{ .I64 = 0 }});
    try t.ser.run(serialize, @as(i128, 0), &.{.{ .I128 = 0 }});

    // unsigned
    try t.ser.run(serialize, @as(u8, 0), &.{.{ .U8 = 0 }});
    try t.ser.run(serialize, @as(u16, 0), &.{.{ .U16 = 0 }});
    try t.ser.run(serialize, @as(u32, 0), &.{.{ .U32 = 0 }});
    try t.ser.run(serialize, @as(u64, 0), &.{.{ .U64 = 0 }});
    try t.ser.run(serialize, @as(u128, 0), &.{.{ .U128 = 0 }});
}
