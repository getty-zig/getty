const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Union: type) type {
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
            undefined,
            undefined,
            undefined,
            visitUnion,
            undefined,
        );

        const Value = Union;

        fn visitUnion(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            return error.Unsupported;
        }
    };
}
