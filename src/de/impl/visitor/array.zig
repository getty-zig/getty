const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Array: type) type {
    return struct {
        allocator: ?std.mem.Allocator = null,

        const Self = @This();
        const impl = @"impl Visitor"(Array);

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
            impl.visitor.visitString,
            undefined,
            undefined,
        );
    };
}
fn @"impl Visitor"(comptime Array: type) type {
    const Self = Visitor(Array);

    return struct {
        pub const visitor = struct {
            pub const Value = Array;

            pub fn visitSeq(self: Self, comptime Deserializer: type, sequenceAccess: anytype) Deserializer.Error!Value {
                var seq: Value = undefined;
                var seen: usize = 0;

                errdefer {
                    if (self.allocator) |allocator| {
                        if (seq.len > 0) {
                            var i: usize = 0;

                            while (i < seen) : (i += 1) {
                                getty.de.free(allocator, seq[i]);
                            }
                        }
                    }
                }

                switch (seq.len) {
                    0 => seq = .{},
                    else => for (seq) |*elem| {
                        if (try sequenceAccess.nextElement(Child)) |value| {
                            elem.* = value;
                            seen += 1;
                        } else {
                            // End of sequence was reached early.
                            return error.InvalidLength;
                        }
                    },
                }

                // Expected end of sequence, but found an element.
                if ((try sequenceAccess.nextElement(Child)) != null) {
                    return error.InvalidLength;
                }

                return seq;
            }

            pub fn visitString(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                defer getty.de.free(self.allocator.?, input);

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
    };
}
