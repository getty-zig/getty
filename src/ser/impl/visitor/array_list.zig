const getty = @import("../../../lib.zig");

const ArrayListVisitor = @This();

pub fn visitor(self: *ArrayListVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *ArrayListVisitor,
    serialize,
);

fn serialize(_: *ArrayListVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty.serialize(serializer, value.items);
}
