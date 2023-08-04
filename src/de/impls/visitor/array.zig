const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Array: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitSeq = visitSeq,
                .visitString = visitString,
            },
        );

        const Value = Array;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var array: Value = undefined;
            var seen: usize = 0;

            errdefer {
                if (ally) |a| {
                    for (array[0..seen]) |v| {
                        free(a, Deserializer, v);
                    }
                }
            }

            switch (array.len) {
                0 => array = .{},
                else => for (&array) |*elem| {
                    if (try seq.nextElement(ally, Child)) |value| {
                        elem.* = value;
                        seen += 1;
                    } else {
                        // End of sequence was reached early.
                        return error.InvalidLength;
                    }
                },
            }

            // Expected end of sequence, but found an element.
            if ((try seq.nextElement(ally, Child)) != null) {
                return error.InvalidLength;
            }

            return array;
        }

        fn visitString(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (Child == u8) {
                var string: Value = undefined;

                if (input.len == string.len) {
                    @memcpy(&string, input);
                    return string;
                }
            }

            return error.InvalidType;
        }

        const Child = std.meta.Child(Value);
    };
}
