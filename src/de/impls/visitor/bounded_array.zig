const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime BoundedArray: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = BoundedArray;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var arr = Value.init(0) catch return error.InvalidValue;

            if (@TypeOf(arr.len) == u0 or @TypeOf(arr.len) == i0) {
                return arr;
            }

            while (try seq.nextElement(ally, std.meta.Child(@TypeOf(arr.buffer)))) |value| {
                arr.append(value) catch return error.InvalidValue;
            }

            return arr;
        }
    };
}
