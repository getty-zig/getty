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

            const m = (try serializer.serializeMap(value.count())).mapSerialize();
            {
                var iterator = value.iterator();
                while (iterator.next()) |entry| {
                    try m.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
                }
            }
            return try m.end();
        }
    };
};
