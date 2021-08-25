const meta = @import("std").meta;
const getty = @import("../../../lib.zig");

const TupleVisitor = @This();

pub fn visitor(self: *TupleVisitor) V {
    return .{ .context = self };
}

const V = getty.ser.Visitor(
    *TupleVisitor,
    serialize,
);

fn serialize(_: *TupleVisitor, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const tuple = (try serializer.serializeTuple(meta.fields(T).len)).tuple();
    inline for (@typeInfo(T).Struct.fields) |field| {
        try tuple.serializeElement(@field(value, field.name));
    }
    return try tuple.end();
}
