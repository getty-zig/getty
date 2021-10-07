const getty = @import("../../../lib.zig");

pub usingnamespace getty.Ser(
    *@This(),
    serialize,
);

fn serialize(_: *@This(), value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const seq = (try serializer.serializeSequence(value.len)).sequenceSerialize();
    for (value) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}
