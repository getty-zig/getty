const getty = @import("../../../lib.zig");

const ErrorVisitor = @This();

pub fn visitor(self: *ErrorVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *ErrorVisitor,
    serialize,
);

fn serialize(_: *ErrorVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty.serialize(serializer, @as([]const u8, @errorName(value)));
}
