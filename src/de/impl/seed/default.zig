const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn DefaultSeed(comptime Value: type) type {
    return struct {
        const Self = @This();
        const impl = @"impl DefaultSeed"(Value);

        pub usingnamespace getty.de.Seed(
            Self,
            impl.seed.Value,
            impl.seed.deserialize,
        );
    };
}

fn @"impl DefaultSeed"(comptime V: type) type {
    const Self = DefaultSeed(V);

    return struct {
        pub const seed = struct {
            pub const Value = V;

            pub fn deserialize(
                self: Self,
                allocator: ?std.mem.Allocator,
                deserializer: anytype,
            ) @TypeOf(deserializer).Error!Value {
                _ = self;

                return try getty.deserialize(allocator, Value, deserializer);
            }
        };
    };
}
