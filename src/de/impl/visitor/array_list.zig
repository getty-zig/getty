const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime ArrayList: type) type {
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
            var list = ArrayList.init(self.allocator);
            errdefer list.deinit();

            while (try sequenceAccess.nextElement(Child)) |value| {
                try list.append(value);
            }

            return list;
        }
    };
}
