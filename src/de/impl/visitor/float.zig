const getty = @import("../../../lib.zig");

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

            pub fn visitFloat(self: Self, comptime Error: type, input: anytype) Error!Value {
                _ = self;

                return @floatCast(Value, input);
            }

            pub fn visitInt(self: Self, comptime Error: type, input: anytype) Error!Value {
                _ = self;

                return @intToFloat(Value, input);
            }
        };
    };
}
