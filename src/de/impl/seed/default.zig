const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn DefaultSeed(comptime Value: type) type {
    return struct {
        const Self = @This();
        const impl = @"impl DefaultSeed";

        /// Implements `getty.de.Seed`.
        pub usingnamespace getty.de.Seed(
            Self,
            impl.seed(Value).Value,
            impl.seed(Value).deserialize,
        );
    };
}

const @"impl DefaultSeed" = struct {
    fn seed(comptime V: type) type {
        return struct {
            const Value = V;

            fn deserialize(self: DefaultSeed(V), allocator: ?*std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                _ = self;

                return try getty.deserialize(allocator, Value, deserializer);
            }
        };
    }
};
