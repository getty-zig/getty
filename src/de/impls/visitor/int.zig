const std = @import("std");

const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

pub fn Visitor(comptime Int: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitInt = visitInt,
                .visitString = visitString,
            },
        );

        const Value = Int;

        fn visitInt(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return std.math.cast(Value, input) orelse error.Overflow;
        }

        fn visitString(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
            lt: StringLifetime,
        ) Deserializer.Err!VisitStringReturn(Value) {
            _ = scratch_ally;

            defer if (lt == .heap) result_ally.free(input);

            var int = std.fmt.parseInt(Value, input, 10) catch return error.InvalidValue;

            return .{
                .value = int,
                .used = false,
            };
        }
    };
}
