const getty = @import("../../lib.zig");
const std = @import("std");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).Pointer;

    // Serialize array pointers as slices so that strings are handled properly.
    if (@typeInfo(info.child) == .Array) {
        return try getty.serialize(@as([]const std.meta.Elem(info.child), value), serializer);
    }

    return try getty.serialize(value.*, serializer);
}
