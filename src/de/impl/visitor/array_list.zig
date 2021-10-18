const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime ArrayList: type) type {
    const unmanaged = comptime std.mem.startsWith(
        u8,
        @typeName(ArrayList),
        "std.array_list.ArrayListAlignedUnmanaged",
    );

    return struct {
        allocator: *std.mem.Allocator,

        const Self = @This();
        const Child = std.meta.Child(ArrayList.Slice);

        pub usingnamespace getty.de.Visitor(
            Self,
            ArrayList,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSequence,
            undefined,
            undefined,
            undefined,
        );

        fn visitSequence(self: Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!ArrayList {
            var list = if (unmanaged) ArrayList{} else ArrayList.init(self.allocator);
            errdefer getty.free(self.allocator, list);

            while (try sequenceAccess.nextElement(Child)) |value| {
                try if (unmanaged) list.append(self.allocator, value) else list.append(value);
            }

            return list;
        }
    };
}
