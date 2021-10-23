const getty = @import("../../../lib.zig");
const std = @import("std");

const Ser = @This();
const impl = @"impl Ser";

pub usingnamespace getty.Ser(
    Ser,
    impl.ser.serialize,
);

const @"impl Ser" = struct {
    pub const ser = struct {
        pub fn serialize(self: Ser, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            _ = self;

            const T = @TypeOf(value);

            const tuple = (try serializer.serializeTuple(std.meta.fields(T).len)).tupleSerialize();
            inline for (@typeInfo(T).Struct.fields) |field| {
                try tuple.serializeElement(@field(value, field.name));
            }
            return try tuple.end();
        }
    };
};
