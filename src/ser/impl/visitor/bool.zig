const Visitor = @import("../../../lib.zig").ser.Visitor;

const BoolVisitor = @This();

pub fn visitor(self: *BoolVisitor) V {
    return .{ .context = self };
}

const V = Visitor(
    *BoolVisitor,
    serialize,
);

fn serialize(_: *BoolVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeBool(value);
}
