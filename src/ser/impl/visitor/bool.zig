const Visitor = @import("../../interface.zig").Visitor;

const BoolVisitor = @This();

pub usingnamespace Visitor(
    *BoolVisitor,
    serialize,
);

fn serialize(_: *BoolVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeBool(value);
}
