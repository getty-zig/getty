const t = @import("getty/testing");

const ser = @import("../../ser.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .ErrorSet;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try ser.serialize(@as([]const u8, @errorName(value)), serializer);
}

test "serialize - error" {
    try t.ser.run(error.Foobar, &[_]t.Token{.{ .String = "Foobar" }});
}
