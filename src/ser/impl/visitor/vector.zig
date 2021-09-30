const getty = @import("../../../lib.zig");

const VectorVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *VectorVisitor,
    serialize,
);

fn serialize(_: *VectorVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return switch (@typeInfo(@TypeOf(value))) {
        .Vector => |info| try getty.serialize(@as([info.len]info.child, value), serializer),
        else => @compileError("expected vector, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
    };
}
