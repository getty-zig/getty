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
        pub fn serialize(self: Ser, value: anytype, serializer: anytype) blk: {
            const Serializer = @TypeOf(serializer);

            getty.concepts.@"getty.Serializer"(Serializer);

            break :blk Serializer.Error!Serializer.Ok;
        } {
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
