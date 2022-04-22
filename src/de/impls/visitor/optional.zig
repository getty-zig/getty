const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Optional: type) type {
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
            visitNull,
            undefined,
            undefined,
            visitSome,
            undefined,
        );

        const Value = Optional;

        fn visitNull(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            return null;
        }

        fn visitSome(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try getty.deserialize(allocator, std.meta.Child(Value), deserializer);
        }
    };
}
