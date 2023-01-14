const t = @import("getty/testing");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Enum, .EnumLiteral => true,
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
    return try serializer.serializeEnum(value);
}

test "serialize - enum" {
    // literal
    try t.ser.run(serialize, .foo, &[_]t.Token{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t.ser.run(serialize, .bar, &[_]t.Token{ .{ .Enum = {} }, .{ .String = "bar" } });

    // non-literal
    const T = enum { foo, bar };
    try t.ser.run(serialize, T.foo, &[_]t.Token{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t.ser.run(serialize, T.bar, &[_]t.Token{ .{ .Enum = {} }, .{ .String = "bar" } });
}
