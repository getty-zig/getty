const Visitor = @import("../../interface.zig").Visitor;

const FloatVisitor = @This();

pub usingnamespace Visitor(
    *FloatVisitor,
    serialize,
);

fn serialize(_: *FloatVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeFloat(value);
}
