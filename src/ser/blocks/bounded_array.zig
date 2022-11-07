//! The default Serialization Block for std.BoundedArray values.

const std = @import("std");

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "bounded_array");
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    var s = try serializer.serializeSeq(value.len);
    const seq = s.seq();
    for (value.constSlice()) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}
