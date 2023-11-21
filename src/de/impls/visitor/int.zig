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
            _: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
        ) Deserializer.Err!Value {
            return std.math.cast(Value, input) orelse error.Overflow;
        }

        fn visitString(
            _: Self,
            ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
            lt: StringLifetime,
        ) Deserializer.Err!VisitStringReturn(Value) {
            defer if (lt == .heap) ally.free(input);

            const int = std.fmt.parseInt(Value, input, 10) catch return error.InvalidValue;

            return .{
                .value = int,
                .used = false,
            };
        }
    };
}
