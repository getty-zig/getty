const getty = @import("../../../lib.zig");
const std = @import("std");

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

            const info = @typeInfo(@TypeOf(value)).Pointer;

            // Serialize array pointers as slices so that strings are handled properly.
            if (@typeInfo(info.child) == .Array) {
                return try getty.serialize(@as([]const std.meta.Elem(info.child), value), serializer);
            }

            return try getty.serialize(value.*, serializer);
        }
    };
};
