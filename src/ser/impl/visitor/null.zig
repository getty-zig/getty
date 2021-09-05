const Visitor = @import("../../interface.zig").Visitor;

const NullVisitor = @This();

pub usingnamespace Visitor(
    *NullVisitor,
    serialize,
);

fn serialize(_: *NullVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = value;

    return try serializer.serializeNull();
}
