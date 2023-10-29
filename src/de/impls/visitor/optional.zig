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

        fn visitNull(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return null;
        }

        fn visitSome(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            deserializer: anytype,
        ) @TypeOf(deserializer).Err!Value {
            _ = scratch_ally;

            var result = try getty_deserialize(result_ally, std.meta.Child(Value), deserializer);
            return result.value;
        }
    };
}
