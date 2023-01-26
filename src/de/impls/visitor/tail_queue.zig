const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime TailQueue: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = TailQueue;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = Value{};
            errdefer free(allocator.?, list);

            const Child = std.meta.fieldInfo(Value.Node, .data).type;

            while (try seq.nextElement(allocator, Child)) |value| {
                var node = try allocator.?.create(Value.Node);
                node.* = .{ .data = value };
                list.append(node);
            }

            return list;
        }
    };
}
