//! The default Serialization Block for string values.

const std = @import("std");

pub fn is(comptime T: type) bool {
    return comptime std.meta.trait.isZigString(T);
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeString(value);
}
