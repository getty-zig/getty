const getty = @import("../../../lib.zig");
const Elem = @import("std").meta.Elem;

const PointerVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *PointerVisitor,
    serialize,
);

fn serialize(_: *PointerVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).Pointer;

    if (@typeInfo(info.child) == .Array) {
        return try getty.serialize(@as([]const Elem(info.child), value), serializer);
    }

    return try getty.serialize(value.*, serializer);
}
