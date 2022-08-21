const getty = @import("../../lib.zig");
const std = @import("std");

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "array_list");
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const seq = (try serializer.serializeSeq(value.items.len)).seq();
    for (value.items) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}
