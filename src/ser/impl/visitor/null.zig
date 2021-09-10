const Visitor = @import("../../interface.zig").Visitor;

const NullVisitor = @This();

pub usingnamespace Visitor(
    *NullVisitor,
    serialize,
);

fn serialize(_: *NullVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = value;

    return try serializer.serializeNull();
}
