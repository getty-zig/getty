const getty = @import("../../../lib.zig");

const ArrayListVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *ArrayListVisitor,
    serialize,
);

fn serialize(_: *ArrayListVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty.serialize(value.items, serializer);
}
