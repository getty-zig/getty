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

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (ally == null) {
                return error.MissingAllocator;
            }

            const a = ally.?;

            var list = Value{};
            errdefer free(a, Deserializer, list);

            const Child = std.meta.fieldInfo(Value.Node, .data).type;

            while (try seq.nextElement(a, Child)) |value| {
                var node = try a.create(Value.Node);
                node.* = .{ .data = value };
                list.append(node);
            }

            return list;
        }
    };
}
