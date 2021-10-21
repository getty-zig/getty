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

            return switch (@typeInfo(@TypeOf(value))) {
                .Vector => |info| try getty.serialize(@as([info.len]info.child, value), serializer),
                else => @compileError("expected vector, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
            };
        }
    };
};
