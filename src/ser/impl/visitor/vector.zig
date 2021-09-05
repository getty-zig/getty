const getty = @import("../../../lib.zig");

const VectorVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *VectorVisitor,
    serialize,
);

fn serialize(_: *VectorVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return switch (@typeInfo(@TypeOf(value))) {
        .Vector => |info| try getty.serialize(serializer, @as([info.len]info.child, value)),
        else => unreachable,
    };
}
