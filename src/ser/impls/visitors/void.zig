const getty = @import("../../../lib.zig");

const VoidVisitor = @This();

pub fn visitor(self: *VoidVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *VoidVisitor,
    serialize,
);

fn serialize(_: *VoidVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = value;

    return try serializer.serializeVoid();
}
