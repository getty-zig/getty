const getty = @import("../../lib.zig");
const std = @import("std");

pub fn is(comptime T: type) bool {
    return std.mem.startsWith(u8, @typeName(T), "std.array_list");
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty.serialize(value.items, serializer);
}
