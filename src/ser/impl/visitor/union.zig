const getty = @import("../../../lib.zig");

const UnionVisitor = @This();

pub fn visitor(self: *UnionVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *UnionVisitor,
    serialize,
);

fn serialize(_: *UnionVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    switch (@typeInfo(@TypeOf(value))) {
        .Union => |info| {
            if (info.tag_type) |Tag| {
                inline for (info.fields) |field| {
                    if (@field(Tag, field.name) == value) {
                        return try getty.serialize(serializer, @field(value, field.name));
                    }
                }
            } else {
                @compileError("type `" ++ @typeName(@TypeOf(value)) ++ "` is not supported");
            }
        },
        else => unreachable,
    }
}
