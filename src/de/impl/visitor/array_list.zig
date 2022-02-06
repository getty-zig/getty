const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime ArrayList: type) type {
    return struct {
        allocator: std.mem.Allocator,

        const Self = @This();
        const impl = @"impl Visitor"(ArrayList);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
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

fn @"impl Visitor"(comptime ArrayList: type) type {
    const Self = Visitor(ArrayList);

    return struct {
        pub const visitor = struct {
            pub const Value = ArrayList;

            pub fn visitSeq(self: Self, comptime Deserializer: type, sequenceAccess: anytype) Deserializer.Error!Value {
                var list = if (unmanaged) ArrayList{} else ArrayList.init(self.allocator);
                errdefer getty.de.free(self.allocator, list);

                while (try sequenceAccess.nextElement(std.meta.Child(ArrayList.Slice))) |value| {
                    try if (unmanaged) list.append(self.allocator, value) else list.append(value);
                }

                return list;
            }

            const unmanaged = std.mem.startsWith(
                u8,
                @typeName(ArrayList),
                "std.array_list.ArrayListAlignedUnmanaged",
            );
        };
    };
}
