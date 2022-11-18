const std = @import("std");

const de = @import("../../../de.zig").de;

pub fn Visitor(comptime LinkedList: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = LinkedList;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = Value{};
            errdefer de.free(allocator.?, list);

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
