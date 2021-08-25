const meta = @import("std").meta;
const getty = @import("../../../lib.zig");

const PointerVisitor = @This();

pub fn visitor(self: *PointerVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *PointerVisitor,
    serialize,
);

fn serialize(_: *PointerVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).Pointer;

    if (@typeInfo(info.child) == .Array) {
        return try getty.serialize(serializer, @as([]const meta.Elem(info.child), value));
    }

    return try getty.serialize(serializer, value.*);
}
