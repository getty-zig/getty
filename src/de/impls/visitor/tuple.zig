const std = @import("std");

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

        fn visitSeq(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            @setEvalBranchQuota(10_000);

            const fields = std.meta.fields(Value);
            const len = fields.len;

            var tuple: Value = undefined;
            comptime var seen: usize = 0;

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
