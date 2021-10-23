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

            const st = (try serializer.serializeStruct(@typeName(T), std.meta.fields(T).len)).structSerialize();
            inline for (@typeInfo(T).Struct.fields) |field| {
                if (field.field_type != void) {
                    try st.serializeField(field.name, @field(value, field.name));
                }
            }
            return try st.end();
        }
    };
};
