const getty = @import("../../../lib.zig");

const NullVisitor = @This();

pub fn visitor(self: *NullVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *NullVisitor,
    serialize,
);

fn serialize(_: *NullVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = value;

    return try serializer.serializeNull();
}
