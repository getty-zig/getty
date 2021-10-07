const getty = @import("../../../lib.zig");

pub usingnamespace getty.Ser(
    *@This(),
    serialize,
);

fn serialize(_: *@This(), value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return switch (@typeInfo(@TypeOf(value))) {
        .Vector => |info| try getty.serialize(@as([info.len]info.child, value), serializer),
        else => @compileError("expected vector, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
    };
}
