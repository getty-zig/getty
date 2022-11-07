const std = @import("std");

const de = @import("../../../de.zig");

pub fn Visitor(comptime Optional: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitNull,
            undefined,
            visitSome,
            undefined,
            undefined,
            undefined,
        );

        const Value = Optional;

        fn visitNull(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            return null;
        }

        fn visitSome(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try de.deserialize(allocator, std.meta.Child(Value), deserializer);
        }
    };
}
