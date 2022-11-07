//! The default Serialization Block for one pointer values.

const std = @import("std");

const ser = @import("../../ser.zig");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).Pointer;

    // Serialize array pointers as slices so that strings are handled properly.
    if (@typeInfo(info.child) == .Array) {
        return try ser.serialize(@as([]const std.meta.Elem(info.child), value), serializer);
    }

    return try ser.serialize(value.*, serializer);
}
