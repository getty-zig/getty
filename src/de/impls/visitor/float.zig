const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Float: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitFloat = visitFloat,
                .visitInt = visitInt,
            },
        );

        const Value = Float;

        fn visitFloat(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return @floatCast(input);
        }

        fn visitInt(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return @floatFromInt(input);
        }
    };
}
