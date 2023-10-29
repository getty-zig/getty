const std = @import("std");

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

        fn visitSeq(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var list = Value{};

            var current: ?*Value.Node = null;
            while (try seq.nextElement(ally, Value.Node.Data)) |value| {
                var node = try ally.create(Value.Node);
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
