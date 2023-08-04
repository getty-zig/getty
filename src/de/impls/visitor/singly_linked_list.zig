const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime SinglyLinkedList: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = SinglyLinkedList;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (ally == null) {
                return error.MissingAllocator;
            }

            const a = ally.?;

            var list = Value{};
            errdefer free(a, Deserializer, list);

            var current: ?*Value.Node = null;
            while (try seq.nextElement(a, Value.Node.Data)) |value| {
                var node = try a.create(Value.Node);
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
