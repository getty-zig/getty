const std = @import("std");

const Ignored = @import("../../impls/seed/ignored.zig").Ignored;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime BitSet: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitSeq = visitSeq,
            },
        );

        const Value = BitSet;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var bitset = Value.initEmpty();

            if (Value.bit_length == 0) {
                if (try seq.nextElement(ally, Ignored) != null) {
                    return error.InvalidLength;
                }

                return bitset;
            }

            // Deserialize bits from N to 1, where N is the bitset's bit
            // length.
            //
            // NOTE: The 0th bit needs to be deserialized separately due to
            // compile errors related to the shift bit being too large or
            // something.
            comptime var i: usize = Value.bit_length - 1;
            inline while (i > 0) : (i -= 1) {
                if (try seq.nextElement(ally, Value.MaskInt)) |bit| {
                    switch (bit) {
                        0 => {},
                        1 => bitset.set(i),
                        else => return error.InvalidValue,
                    }
                } else {
                    return error.InvalidValue;
                }
            }

            // Deserialize 0th bit.
            if (try seq.nextElement(ally, Value.MaskInt)) |bit| {
                switch (bit) {
                    0 => {},
                    1 => bitset.set(0),
                    else => return error.InvalidValue,
                }
            } else {
                return error.InvalidValue;
            }

            // Check for end of sequence.
            if (try seq.nextElement(ally, Ignored) != null) {
                return error.InvalidLength;
            }

            return bitset;
        }
    };
}
