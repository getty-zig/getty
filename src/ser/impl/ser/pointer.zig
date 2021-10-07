const getty = @import("../../../lib.zig");
const std = @import("std");

pub usingnamespace getty.Ser(
    *@This(),
    serialize,
);

fn serialize(_: *@This(), value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).Pointer;

    if (@typeInfo(info.child) == .Array) {
        return try getty.serialize(@as([]const std.meta.Elem(info.child), value), serializer);
    }

    return try getty.serialize(value.*, serializer);
}
