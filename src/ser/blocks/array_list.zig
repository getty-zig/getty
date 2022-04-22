const getty = @import("../../lib.zig");
const std = @import("std");

pub fn is(comptime T: type) bool {
    return std.mem.startsWith(u8, @typeName(T), "std.array_list");
}

// TODO: Change to serialize as a sequence. If they want to serialize an
// ArrayList as a string, have them pass in list.items.
pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty.serialize(value.items, serializer);
}
