const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Int: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        const Value = Int;

        fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return @intCast(Value, input);
        }
    };
}
