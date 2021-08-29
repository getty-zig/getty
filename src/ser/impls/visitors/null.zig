const Visitor = @import("../../../lib.zig").ser.Visitor;

const NullVisitor = @This();

pub fn visitor(self: *NullVisitor) V {
    return .{ .context = self };
}

const V = Visitor(
    *NullVisitor,
    serialize,
);

fn serialize(_: *NullVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = value;

    return try serializer.serializeNull();
}
