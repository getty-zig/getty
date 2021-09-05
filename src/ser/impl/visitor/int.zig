const Visitor = @import("../../interface.zig").Visitor;

const IntVisitor = @This();

pub usingnamespace Visitor(
    *IntVisitor,
    serialize,
);

fn serialize(_: *IntVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeInt(value);
}
