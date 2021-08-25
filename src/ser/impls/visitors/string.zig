const getty = @import("../../../lib.zig");

const StringVisitor = @This();

pub fn visitor(self: *StringVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *StringVisitor,
    serialize,
);

fn serialize(_: *StringVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeString(value);
}
