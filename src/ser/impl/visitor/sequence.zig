const Visitor = @import("../../../lib.zig").ser.Visitor;

const SequenceVisitor = @This();

pub fn visitor(self: *SequenceVisitor) V {
    return .{ .context = self };
}

const V = Visitor(
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
