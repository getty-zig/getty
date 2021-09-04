const Visitor = @import("../../interface.zig").Visitor;

const FloatVisitor = @This();

pub fn visitor(self: *FloatVisitor) V {
    return .{ .context = self };
}

const V = Visitor(
    *FloatVisitor,
    serialize,
);

fn serialize(_: *FloatVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeFloat(value);
}
