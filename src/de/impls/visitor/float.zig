const std = @import("std");

const de = @import("../../../de.zig").de;

pub fn Visitor(comptime Float: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{
                .visitFloat = visitFloat,
                .visitInt = visitInt,
            },
        );

        const Value = Float;

        fn visitFloat(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return @floatCast(Value, input);
        }

        fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return @intToFloat(Value, input);
        }
    };
}
