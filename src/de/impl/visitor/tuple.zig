const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Tuple: type) type {
    return struct {
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

            pub fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
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

        const fields = std.meta.fields(Tuple);
        const length = std.meta.fields(Tuple).len;
    };
}
