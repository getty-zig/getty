const getty = @import("../../../lib.zig");

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

            return switch (@typeInfo(@TypeOf(value))) {
                .Vector => |info| try getty.serialize(@as([info.len]info.child, value), serializer),
                else => @compileError("expected vector, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
            };
        }
    };
};
