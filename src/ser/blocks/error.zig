const getty_serialize = @import("../serialize.zig").serialize;
const t = @import("../testing.zig");

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
    return try getty_serialize(@as([]const u8, @errorName(value)), serializer);
}

test "serialize - error" {
    try t.run(serialize, error.Foobar, &.{.{ .String = "Foobar" }});
}
