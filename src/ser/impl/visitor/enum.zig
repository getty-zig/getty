const Visitor = @import("../../interface.zig").Visitor;

const EnumVisitor = @This();

pub usingnamespace Visitor(
    *EnumVisitor,
    serialize,
);

fn serialize(_: *EnumVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try serializer.serializeEnum(value);
}
