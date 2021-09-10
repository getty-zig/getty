const Visitor = @import("../../interface.zig").Visitor;

const BoolVisitor = @This();

pub usingnamespace Visitor(
    *BoolVisitor,
    serialize,
);

fn serialize(_: *BoolVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeBool(value);
}
