const getty = @import("../../../lib.zig");

const Ser = @This();
const impl = @"impl Ser";

pub usingnamespace getty.Ser(
    Ser,
    impl.ser.serialize,
);

const @"impl Ser" = struct {
    const ser = struct {
        fn serialize(self: Ser, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            _ = self;

            const seq = (try serializer.serializeSequence(value.len())).sequenceSerialize();
            {
                var iterator = value.first;
                while (iterator) |node| : (iterator = node.next) {
                    try seq.serializeElement(node.data);
                }
            }
            return try seq.end();
        }
    };
};
