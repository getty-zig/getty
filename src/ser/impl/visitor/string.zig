const Visitor = @import("../../interface.zig").Visitor;

const StringVisitor = @This();

pub usingnamespace Visitor(
    *StringVisitor,
    serialize,
);

fn serialize(_: *StringVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeString(value);
}
