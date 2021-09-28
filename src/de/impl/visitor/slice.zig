const std = @import("std");
const interface = @import("../../interface.zig");

pub fn Visitor(comptime T: type) type {
    return struct {
        allocator: *std.mem.Allocator,

        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace interface.Visitor(
            *Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSequence,
            visitSlice,
            undefined,
            undefined,
        );

        const Value = T;

        fn visitSequence(self: *Self, seqAccess: anytype) @TypeOf(seqAccess).Error!Value {
            var list = std.ArrayList(std.meta.Child(Value)).init(self.allocator);
            errdefer list.deinit();

            while (try seqAccess.nextElement(std.meta.Child(Value))) |elem| {
                // TODO: change unreachable
                list.append(elem) catch unreachable;
            }

            return list.toOwnedSlice();
        }

        fn visitSlice(self: *Self, comptime Error: type, input: anytype) Error!Value {
            return self.allocator.dupe(std.meta.Child(Value), input) catch unreachable;
        }
    };
}
