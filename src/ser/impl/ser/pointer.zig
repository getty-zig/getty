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

            const info = @typeInfo(@TypeOf(value)).Pointer;

            // Serialize array pointers as slices so that strings are handled properly.
            if (@typeInfo(info.child) == .Array) {
                return try getty.serialize(@as([]const std.meta.Elem(info.child), value), serializer);
            }

            return try getty.serialize(value.*, serializer);
        }
    };
};
