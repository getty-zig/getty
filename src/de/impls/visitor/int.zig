const std = @import("std");

const de = @import("../../de.zig").de;

pub fn Visitor(comptime Int: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{ .visitInt = visitInt },
        );

        const Value = Int;

        fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return @intCast(Value, input);
        }
    };
}
