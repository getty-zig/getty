const Visitor = @import("../../../lib.zig").ser.Visitor;

const IntVisitor = @This();

pub fn visitor(self: *IntVisitor) V {
    return .{ .context = self };
}

const V = Visitor(
    *IntVisitor,
    serialize,
);

fn serialize(_: *IntVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeInt(value);
}
