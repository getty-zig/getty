const std = @import("std");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Struct and @typeInfo(T).Struct.is_tuple;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    var s = try serializer.serializeSeq(std.meta.fields(T).len);
    const seq = s.seq();
    inline for (@typeInfo(T).Struct.fields) |field| {
        try seq.serializeElement(@field(value, field.name));
    }
    return try seq.end();
}
