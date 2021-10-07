const getty = @import("../../../lib.zig");
const std = @import("std");

pub usingnamespace getty.Ser(
    *@This(),
    serialize,
);

fn serialize(_: *@This(), value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    const tuple = (try serializer.serializeTuple(std.meta.fields(T).len)).tupleSerialize();
    inline for (@typeInfo(T).Struct.fields) |field| {
        try tuple.serializeElement(@field(value, field.name));
    }
    return try tuple.end();
}
