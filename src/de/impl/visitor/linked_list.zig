const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime LinkedList: type) type {
    return struct {
        allocator: *std.mem.Allocator,

        const Self = @This();
        const Child = LinkedList.Node.Data;

        pub usingnamespace getty.de.Visitor(
            Self,
            LinkedList,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSequence,
            undefined,
            undefined,
            undefined,
        );

        fn visitSequence(self: Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!LinkedList {
            var list = LinkedList{};
            errdefer getty.de.free(self.allocator, list);

            var current: ?*LinkedList.Node = null;

            while (try sequenceAccess.nextElement(Child)) |value| {
                var node = try self.allocator.create(LinkedList.Node);
                node.* = .{ .data = value };

                if (current) |c| {
                    c.*.insertAfter(node);
                    current = c.next;
                } else {
                    list.prepend(node);
                    current = list.first;
                }
            }

            return list;
        }
    };
}
