const getty = @import("../../../lib.zig");

const OptionalVisitor = @This();

pub fn visitor(self: *OptionalVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *OptionalVisitor,
    serialize,
);

fn serialize(_: *OptionalVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    if (value) |v| {
        return try getty.serialize(serializer, v);
    }

    return try getty.serialize(serializer, null);
}
