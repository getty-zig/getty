const Visitor = @import("../../interface.zig").Visitor;

const SequenceVisitor = @This();

pub usingnamespace Visitor(
    *SequenceVisitor,
    serialize,
);

fn serialize(_: *SequenceVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const seq = (try serializer.serializeSequence(value.len)).sequence();
    for (value) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}
