const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime TailQueue: type) type {
    return struct {
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
            impl.visitor.visitSeq,
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

            pub fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!TailQueue {
                var list = TailQueue{};
                errdefer getty.de.free(allocator.?, list);

                while (try seq.nextElement(allocator, Child)) |value| {
                    var node = try allocator.?.create(TailQueue.Node);
                    node.* = .{ .data = value };
                    list.append(node);
                }

                return list;
            }

            const Child = std.meta.fieldInfo(TailQueue.Node, .data).field_type;
        };
    };
}
