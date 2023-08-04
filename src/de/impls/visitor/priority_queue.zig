const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime PriorityQueue: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = PriorityQueue;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (ally == null) {
                return error.MissingAllocator;
            }

            const a = ally.?;

            const T = std.meta.Child(std.meta.FieldType(Value, .items));
            const Context = std.meta.FieldType(Value, .context);

            if (@sizeOf(Context) != 0) {
                @compileError("non void context is not supported");
            }

            var queue = Value.init(a, undefined);
            errdefer free(a, Deserializer, queue);

            while (try seq.nextElement(a, T)) |elem| {
                try queue.add(elem);
            }

            return queue;
        }
    };
}
