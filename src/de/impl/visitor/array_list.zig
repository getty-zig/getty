const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime ArrayList: type) type {
    return struct {
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

            pub fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
                var list = if (unmanaged) ArrayList{} else ArrayList.init(allocator.?);
                errdefer getty.de.free(allocator.?, list);

                while (try seq.nextElement(allocator, std.meta.Child(ArrayList.Slice))) |value| {
                    try if (unmanaged) list.append(allocator.?, value) else list.append(value);
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
