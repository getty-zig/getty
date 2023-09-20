const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime PriorityDequeue: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = PriorityDequeue;

        fn visitSeq(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            const T = std.meta.Child(std.meta.FieldType(Value, .items));
            const Context = std.meta.FieldType(Value, .context);

            if (@sizeOf(Context) != 0) {
                @compileError("non void context is not supported");
            }

            var deque = Value.init(ally, undefined);
            errdefer free(ally, Deserializer, deque);

            while (try seq.nextElement(ally, T)) |elem| {
                try deque.add(elem);
            }

            return deque;
        }
    };
}
