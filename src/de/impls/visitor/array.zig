const std = @import("std");

const de = @import("../../../de.zig").de;

pub fn Visitor(comptime Array: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{
                .visitSeq = visitSeq,
                .visitString = visitString,
            },
        );

        const Value = Array;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var array: Value = undefined;
            var seen: usize = 0;

            errdefer {
                if (allocator) |alloc| {
                    if (array.len > 0) {
                        var i: usize = 0;

                        while (i < seen) : (i += 1) {
                            de.free(alloc, array[i]);
                        }
                    }
                }
            }

            switch (array.len) {
                0 => array = .{},
                else => for (array) |*elem| {
                    if (try seq.nextElement(allocator, Child)) |value| {
                        elem.* = value;
                        seen += 1;
                    } else {
                        // End of sequence was reached early.
                        return error.InvalidLength;
                    }
                },
            }

            // Expected end of sequence, but found an element.
            if ((try seq.nextElement(allocator, Child)) != null) {
                return error.InvalidLength;
            }

            return array;
        }

        fn visitString(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            defer de.free(allocator.?, input);

            if (Child == u8) {
                var string: Value = undefined;

                if (input.len == string.len) {
                    std.mem.copy(u8, &string, input);
                    return string;
                }
            }

            return error.InvalidType;
        }

        const Child = std.meta.Child(Value);
    };
}
