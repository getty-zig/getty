const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Array: type) type {
    return struct {
        allocator: ?*std.mem.Allocator = null,

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
            impl.visitor.visitSequence,
            undefined,
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

            pub fn visitSequence(self: Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
                var seq: Value = undefined;

                if (@typeInfo(Value).Array.len == 0) {
                    seq = .{};
                } else {
                    var seen: usize = 0;

                    errdefer {
                        var i: usize = 0;

                        while (i < seen) : (i += 1) {
                            if (self.allocator) |allocator| getty.de.free(allocator, seq[i]);
                        }
                    }

                    for (seq) |*elem| {
                        if (try sequenceAccess.nextElement(std.meta.Child(Value))) |value| {
                            elem.* = value;
                            seen += 1;
                        }
                    }
                }

                if (try sequenceAccess.nextElement(std.meta.Child(Value))) |_| {
                    return error.InvalidLength;
                }

                return seq;
            }
        };
    };
}
