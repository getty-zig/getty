const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Tuple: type) type {
    return struct {
        allocator: ?std.mem.Allocator = null,

        const Self = @This();
        const impl = @"impl Visitor"(Tuple);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            impl.visitor.visitSeq,
            undefined,
            undefined,
            undefined,
        );
    };
}
fn @"impl Visitor"(comptime Tuple: type) type {
    const Self = Visitor(Tuple);

    return struct {
        pub const visitor = struct {
            pub const Value = Tuple;

            pub fn visitSeq(_: Self, comptime Deserializer: type, sequenceAccess: anytype) Deserializer.Error!Value {
                var seq: Value = undefined;
                // TODO: what is this?
                //var seen: usize = 0;

                //errdefer {
                //comptime var i: usize = 0;

                //if (self.allocator) |allocator| {
                //if (length > 0) {
                //inline while (i < seen) : (i += 1) {
                //getty.de.free(allocator, seq[i]);
                //}
                //}
                //}
                //}

                switch (length) {
                    0 => seq = .{},
                    else => {
                        comptime var i: usize = 0;

                        inline while (i < length) : (i += 1) {
                            // NOTE: Using an if to unwrap `value` runs into a
                            // compiler bug, so this is a workaround.
                            const value = try sequenceAccess.nextElement(fields[i].field_type);
                            if (value == null) return error.InvalidLength;
                            seq[i] = value.?;
                        }
                    },
                }

                // Expected end of sequence, but found an element.
                if ((try sequenceAccess.nextElement(void)) != null) {
                    return error.InvalidLength;
                }

                return seq;
            }
        };

        const fields = std.meta.fields(Tuple);
        const length = std.meta.fields(Tuple).len;
    };
}
