const getty = @import("../../../lib.zig");

const UnionVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *UnionVisitor,
    serialize,
);

fn serialize(_: *UnionVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    switch (@typeInfo(@TypeOf(value))) {
        .Union => |info| {
            if (info.tag_type) |Tag| {
                inline for (info.fields) |field| {
                    if (@field(Tag, field.name) == value) {
                        return try getty.serialize(@field(value, field.name), serializer);
                    }
                }
            } else {
                @compileError("type `" ++ @typeName(@TypeOf(value)) ++ "` is not supported");
            }
        },
        else => unreachable,
    }
}
