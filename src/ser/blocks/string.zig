const std = @import("std");
const t = @import("getty/testing");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.meta.trait.isZigString(T);
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeString(value);
}

test "serialize - string" {
    try t.ser.run("abc", &[_]t.Token{.{ .String = "abc" }});
    try t.ser.run(&[_]u8{ 'a', 'b', 'c' }, &[_]t.Token{.{ .String = "abc" }});
    try t.ser.run(&[_:0]u8{ 'a', 'b', 'c' }, &[_]t.Token{.{ .String = "abc" }});
}
