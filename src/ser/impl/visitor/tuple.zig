const Visitor = @import("../../interface.zig").Visitor;
const fields = @import("std").meta.fields;

const TupleVisitor = @This();

pub fn visitor(self: *TupleVisitor) V {
    return .{ .context = self };
}

const V = Visitor(
    *TupleVisitor,
    serialize,
);

fn serialize(_: *TupleVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const tuple = (try serializer.serializeTuple(fields(T).len)).tuple();
    inline for (@typeInfo(T).Struct.fields) |field| {
        try tuple.serializeElement(@field(value, field.name));
    }
    return try tuple.end();
}
