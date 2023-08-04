const std = @import("std");

const free = @import("../../free.zig").free;
const Ignored = @import("../../impls/seed/ignored.zig").Ignored;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Tuple: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = Tuple;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            @setEvalBranchQuota(10_000);

            const fields = std.meta.fields(Value);
            const len = fields.len;

            var tuple: Value = undefined;
            comptime var seen: usize = 0;

            errdefer {
                if (ally) |a| {
                    if (len > 0) {
                        inline for (tuple, 0..) |v, i| {
                            if (i < seen) {
                                free(a, Deserializer, v);
                            }
                        }
                    }
                }
            }

            switch (len) {
                0 => tuple = .{},
                else => {
                    inline for (0..len) |i| {
                        // NOTE: Using an if to unwrap `value` runs into a
                        // compiler bug, so this is a workaround.
                        const value = try seq.nextElement(ally, fields[i].type);
                        if (value == null) return error.InvalidLength;

                        tuple[i] = value.?;
                        seen += 1;
                    }
                },
            }

            // Expected end of sequence, but found an element.
            if ((try seq.nextElement(ally, Ignored)) != null) {
                return error.InvalidLength;
            }

            return tuple;
        }
    };
}
