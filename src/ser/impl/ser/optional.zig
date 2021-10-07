const getty = @import("../../../lib.zig");

pub usingnamespace getty.Ser(
    *@This(),
    serialize,
);

fn serialize(_: *@This(), value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    if (value) |v| {
        return try getty.serialize(v, serializer);
    }

    return try getty.serialize(null, serializer);
}
