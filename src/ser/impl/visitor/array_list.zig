const getty = @import("../../../lib.zig");

const ArrayListVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *ArrayListVisitor,
    serialize,
);

fn serialize(_: *ArrayListVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty.serialize(serializer, value.items);
}
