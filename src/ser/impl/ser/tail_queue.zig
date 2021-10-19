const getty = @import("../../../lib.zig");

pub usingnamespace getty.Ser(
    *@This(),
    serialize,
);

fn serialize(_: *@This(), value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const seq = (try serializer.serializeSequence(value.len)).sequenceSerialize();
    {
        var iterator = value.first;
        while (iterator) |node| : (iterator = node.next) {
            try seq.serializeElement(node.data);
        }
    }
    return try seq.end();
}
