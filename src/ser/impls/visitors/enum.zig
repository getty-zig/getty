const Visitor = @import("../../../lib.zig").ser.Visitor;

const EnumVisitor = @This();

pub fn visitor(self: *EnumVisitor) V {
    return .{ .context = self };
}

const V = Visitor(
    *EnumVisitor,
    serialize,
);

fn serialize(_: *EnumVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeEnum(value);
}
