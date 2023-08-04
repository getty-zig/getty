const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime ArrayList: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = ArrayList;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            const unmanaged = comptime std.mem.startsWith(
                u8,
                @typeName(Value),
                "array_list.ArrayListAlignedUnmanaged",
            );

            var list = if (unmanaged) ArrayList{} else ArrayList.init(ally.?);
            errdefer free(ally.?, Deserializer, list);

            while (try seq.nextElement(ally, std.meta.Child(ArrayList.Slice))) |value| {
                try if (unmanaged) list.append(ally.?, value) else list.append(value);
            }

            return list;
        }
    };
}
