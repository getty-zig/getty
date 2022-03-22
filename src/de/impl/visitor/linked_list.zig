const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime LinkedList: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSeq,
            undefined,
            undefined,
            undefined,
        );

        const Value = LinkedList;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = Value{};
            errdefer getty.de.free(allocator.?, list);

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
