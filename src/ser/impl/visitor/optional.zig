const getty = @import("../../../lib.zig");

const OptionalVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *OptionalVisitor,
    serialize,
);

fn serialize(_: *OptionalVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    if (value) |v| {
        return try getty.serialize(v, serializer);
    }

    return try getty.serialize(null, serializer);
}
