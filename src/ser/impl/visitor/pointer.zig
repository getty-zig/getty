const getty = @import("../../../lib.zig");
const Elem = @import("std").meta.Elem;

const PointerVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *PointerVisitor,
    serialize,
);

fn serialize(_: *PointerVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).Pointer;

    if (@typeInfo(info.child) == .Array) {
        return try getty.serialize(serializer, @as([]const Elem(info.child), value));
    }

    return try getty.serialize(serializer, value.*);
}
