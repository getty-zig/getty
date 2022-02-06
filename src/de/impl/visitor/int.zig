const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Int: type) type {
    return struct {
        const Self = @This();
        const impl = @"impl Visitor"(Int);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            undefined,
            undefined,
            undefined,
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

fn @"impl Visitor"(comptime Int: type) type {
    const Self = Visitor(Int);

    return struct {
        pub const visitor = struct {
            pub const Value = Int;

            pub fn visitInt(_: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                return @intCast(Value, input);
            }
        };
    };
}
