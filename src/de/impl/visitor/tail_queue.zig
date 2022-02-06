const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime TailQueue: type) type {
    return struct {
        allocator: std.mem.Allocator,

        const Self = @This();
        const impl = @"impl Visitor"(TailQueue);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.TailQueue,
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

fn @"impl Visitor"(comptime TailQueue: type) type {
    const Self = Visitor(TailQueue);

    return struct {
        pub const visitor = struct {
            pub const Value = TailQueue;

            pub fn visitSequence(self: Self, comptime Deserializer: type, sequenceAccess: anytype) Deserializer.Error!TailQueue {
                var list = TailQueue{};
                errdefer getty.de.free(self.allocator, list);

                while (try sequenceAccess.nextElement(Child)) |value| {
                    var node = try self.allocator.create(TailQueue.Node);
                    node.* = .{ .data = value };
                    list.append(node);
                }

                return list;
            }

            const Child = std.meta.fieldInfo(TailQueue.Node, .data).field_type;
        };
    };
}
