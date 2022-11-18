const std = @import("std");

const de = @import("../../../de.zig").de;

pub fn Visitor(comptime Tuple: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = Tuple;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            const fields = std.meta.fields(Value);
            const len = fields.len;

            var tuple: Value = undefined;
            comptime var seen: usize = 0;

            errdefer {
                if (allocator) |alloc| {
                    if (len > 0) {
                        inline for (tuple) |v, i| {
                            if (i < seen) {
                                de.free(alloc, v);
                            }
                        }
                    }
                }
            }

            switch (len) {
                0 => tuple = .{},
                else => {
                    comptime var i: usize = 0;

                    inline while (i < len) : (i += 1) {
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
