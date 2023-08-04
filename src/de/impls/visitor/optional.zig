const std = @import("std");

const getty_deserialize = @import("../../deserialize.zig").deserialize;
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

        fn visitNull(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            return null;
        }

        fn visitSome(_: Self, ally: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try getty_deserialize(ally, std.meta.Child(Value), deserializer);
        }
    };
}
