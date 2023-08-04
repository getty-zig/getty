const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Value: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitSeq = visitSeq,
            },
        );

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (ally == null) {
                return error.MissingAllocator;
            }

            // A DynamicBitSet can only be resized towards its LSB. That is,
            // making [1,1,0,0]'s length = 2 gives [0,0], not [1,1]. And, as
            // far as I know, there's no sane way to copy bits from one bitset
            // to another when their lengths differ.
            //
            // To avoid messing around with resizing bitsets, we instead
            // deserialize into an ArrayList initially. Then, the list's
            // elements are simply copied over to a properly sized bitset.
            var list = try std.ArrayList(Value.MaskInt).initCapacity(ally.?, 8);
            defer list.deinit();

            while (try seq.nextElement(ally, Value.MaskInt)) |bit| {
                switch (bit) {
                    0 => try list.append(0),
                    1 => try list.append(1),
                    else => return error.InvalidValue,
                }
            }

            var bitset = try Value.initEmpty(ally.?, list.items.len);
            errdefer if (Value == std.DynamicBitSet) bitset.deinit() else bitset.deinit(ally.?);

            for (list.items, 0..) |bit, i| {
                if (bit == 1) bitset.set(list.items.len - 1 - i);
            }

            return bitset;
        }
    };
}
