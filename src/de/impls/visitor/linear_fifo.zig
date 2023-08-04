const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime LinearFifo: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = LinearFifo;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (is_buffer_static) {
                var fifo = Value.init();
                errdefer free(ally.?, Deserializer, fifo);

                for (0..fifo.buf.len) |_| {
                    if (try seq.nextElement(ally, Child)) |elem| {
                        fifo.writeItemAssumeCapacity(elem);
                    } else {
                        break;
                    }
                } else if (try seq.nextElement(ally, Child) != null) {
                    // Expected end of sequence, but found an element.
                    return error.InvalidLength;
                }

                return fifo;
            } else if (is_buffer_dynamic) {
                if (ally == null) {
                    return error.MissingAllocator;
                }

                const a = ally.?;

                var fifo = Value.init(a);
                errdefer free(a, Deserializer, fifo);

                while (try seq.nextElement(a, Child)) |elem| {
                    errdefer free(a, Deserializer, elem);
                    try fifo.writeItem(elem);
                }

                return fifo;
            } else {
                if (ally == null) {
                    return error.MissingAllocator;
                }

                const a = ally.?;

                var list = std.ArrayList(Child).init(a);
                errdefer free(a, Deserializer, list);

                while (try seq.nextElement(a, Child)) |elem| {
                    errdefer free(a, Deserializer, elem);
                    try list.append(elem);
                }

                var fifo = Value.init(try list.toOwnedSlice());
                fifo.count = fifo.buf.len;

                return fifo;
            }
        }

        const is_buffer_dynamic = std.meta.FieldType(Value, .allocator) != void;
        const is_buffer_static = @typeInfo(std.meta.FieldType(Value, .buf)) == .Array;

        const Child = std.meta.Child(std.meta.FieldType(Value, .buf));
    };
}
