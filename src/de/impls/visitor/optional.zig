const std = @import("std");

const deserializeLeaky = @import("../../deserialize.zig").deserializeLeaky;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Optional: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitNull = visitNull,
                .visitSome = visitSome,
            },
        );

        const Value = Optional;

        fn visitNull(_: Self, _: std.mem.Allocator, comptime Deserializer: type) Deserializer.Err!Value {
            return null;
        }

        fn visitSome(_: Self, ally: std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Err!Value {
            return try deserializeLeaky(ally, std.meta.Child(Value), deserializer);
        }
    };
}
