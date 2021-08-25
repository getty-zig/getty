const getty = @import("../../../lib.zig");

const FloatVisitor = @This();

pub fn visitor(self: *FloatVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *FloatVisitor,
    serialize,
);

fn serialize(_: *FloatVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeFloat(value);
}
