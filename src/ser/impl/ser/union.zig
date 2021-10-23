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

            switch (@typeInfo(@TypeOf(value))) {
                .Union => |info| if (info.tag_type) |_| {
                    inline for (info.fields) |field| {
                        if (std.mem.eql(u8, field.name, @tagName(value))) {
                            return try getty.serialize(@field(value, field.name), serializer);
                        }
                    }
                } else @compileError("expected tagged union, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
                else => @compileError("expected tagged union, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
            }
        }
    };
};
