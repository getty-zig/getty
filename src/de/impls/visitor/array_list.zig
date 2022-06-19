const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime ArrayList: type) type {
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
            undefined,
        );

        const Value = ArrayList;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            const unmanaged = comptime std.mem.startsWith(
                u8,
                @typeName(Value),
                "std.array_list.ArrayListAlignedUnmanaged",
            );

            var list = if (unmanaged) ArrayList{} else ArrayList.init(allocator.?);
            errdefer getty.de.free(allocator.?, list);

            while (try seq.nextElement(allocator, std.meta.Child(ArrayList.Slice))) |value| {
                try if (unmanaged) list.append(allocator.?, value) else list.append(value);
            }

            return list;
        }
    };
}
