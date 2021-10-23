const getty = @import("../../../lib.zig");

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

            const seq = (try serializer.serializeSequence(value.len)).sequenceSerialize();
            for (value) |elem| {
                try seq.serializeElement(elem);
            }
            return try seq.end();
        }
    };
};
