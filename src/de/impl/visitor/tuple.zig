const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Tuple: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSeq,
            undefined,
            undefined,
            undefined,
        );

        const Value = Tuple;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            const fields = std.meta.fields(Value);
            const length = std.meta.fields(Value).len;

            var tuple: Value = undefined;
            comptime var seen: usize = 0;

            errdefer {
                comptime var i: usize = 0;

                if (allocator) |alloc| {
                    if (length > 0) {
                        inline while (i < seen) : (i += 1) {
                            getty.de.free(alloc, tuple[i]);
                        }
                    }
                }
            }

            switch (length) {
                0 => tuple = .{},
                else => {
                    comptime var i: usize = 0;

                    inline while (i < length) : (i += 1) {
                        // NOTE: Using an if to unwrap `value` runs into a
                        // compiler bug, so this is a workaround.
                        const value = try seq.nextElement(allocator, fields[i].field_type);
                        if (value == null) return error.InvalidLength;

                        tuple[i] = value.?;
                        seen += 1;
                    }
                },
            }

            // Expected end of sequence, but found an element.
            if ((try seq.nextElement(allocator, void)) != null) {
                return error.InvalidLength;
            }

            return tuple;
        }
    };
}
