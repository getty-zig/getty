const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime LinkedList: type) type {
    return struct {
        const Self = @This();
        const impl = @"impl Visitor"(LinkedList);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.LinkedList,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            impl.visitor.visitSeq,
            undefined,
            undefined,
            undefined,
        );
    };
}

fn @"impl Visitor"(comptime LinkedList: type) type {
    const Self = Visitor(LinkedList);

    return struct {
        pub const visitor = struct {
            pub fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!LinkedList {
                var list = LinkedList{};
                errdefer getty.de.free(allocator.?, list);

                var current: ?*LinkedList.Node = null;

                while (try seq.nextElement(allocator, LinkedList.Node.Data)) |value| {
                    var node = try allocator.?.create(LinkedList.Node);
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
    };
}
