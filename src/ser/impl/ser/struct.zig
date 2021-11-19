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
            const fields = std.meta.fields(T);

            const st = (try serializer.serializeStruct(@typeName(T), fields.len)).structSerialize();
            inline for (fields) |field| {
                if (field.field_type != void) {
                    try st.serializeField(field.name, @field(value, field.name));
                }
            }
            return try st.end();
        }
    };
};
