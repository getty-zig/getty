const Visitor = @import("../../interface.zig").Visitor;

const VoidVisitor = @This();

pub fn visitor(self: *VoidVisitor) V {
    return .{ .context = self };
}

const V = Visitor(
    *VoidVisitor,
    serialize,
);

fn serialize(_: *VoidVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = value;

    return try serializer.serializeVoid();
}
