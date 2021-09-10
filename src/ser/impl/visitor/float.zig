const Visitor = @import("../../interface.zig").Visitor;

const FloatVisitor = @This();

pub usingnamespace Visitor(
    *FloatVisitor,
    serialize,
);

fn serialize(_: *FloatVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeFloat(value);
}
