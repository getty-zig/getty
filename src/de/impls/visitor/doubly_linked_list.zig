const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime DoublyLinkedList: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = DoublyLinkedList;

        fn visitSeq(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var list = Value{};

            const Child = std.meta.fieldInfo(Value.Node, .data).type;

            while (try seq.nextElement(ally, Child)) |value| {
                var node = try ally.create(Value.Node);
                node.* = .{ .data = value };
                list.append(node);
            }

            return list;
        }
    };
}
