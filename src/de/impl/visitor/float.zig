const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Float: type) type {
    return struct {
        const Self = @This();
        const impl = @"impl Visitor"(Float);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            undefined,
            undefined,
            impl.visitor.visitFloat,
            impl.visitor.visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );
    };
}

fn @"impl Visitor"(comptime Float: type) type {
    const Self = Visitor(Float);

    return struct {
        pub const visitor = struct {
            pub const Value = Float;

            pub fn visitFloat(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                return @floatCast(Value, input);
            }

            pub fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                return @intToFloat(Value, input);
            }
        };
    };
}
