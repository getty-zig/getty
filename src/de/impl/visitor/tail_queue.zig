const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime TailQueue: type) type {
    return struct {
        allocator: *std.mem.Allocator,

        const Self = @This();
        const Child = std.meta.fieldInfo(TailQueue.Node, .data).field_type;

        pub usingnamespace getty.de.Visitor(
            Self,
            TailQueue,
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

        fn visitSequence(self: Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!TailQueue {
            var list = TailQueue{};
            errdefer getty.free(self.allocator, list);

            while (try sequenceAccess.nextElement(Child)) |value| {
                var node = try self.allocator.create(TailQueue.Node);
                node.* = .{ .data = value };
                list.append(node);
            }

            return list;
        }
    };
}
