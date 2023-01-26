const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime LinkedList: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = LinkedList;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = Value{};
            errdefer free(allocator.?, list);

            {
                var current: ?*Value.Node = null;

                while (try seq.nextElement(allocator, Value.Node.Data)) |value| {
                    var node = try allocator.?.create(Value.Node);
                    node.* = .{ .data = value };

                    if (current) |c| {
                        c.*.insertAfter(node);
                        current = c.next;
                    } else {
                        list.prepend(node);
                        current = list.first;
                    }
                }
            }

            return list;
        }
    };
}
