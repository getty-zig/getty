const getty = @import("../../lib.zig");
const std = @import("std");

pub fn Seq(
    comptime Context: type,
    comptime Error: type,
    comptime nextElementSeed: @TypeOf(struct {
        fn f(c: Context, seed: anytype) Error!?@TypeOf(seed).Value {
            _ = c;

            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.Seq" = struct {
            context: Context,

            const Self = @This();

            pub const Error = Error;

            pub fn nextElementSeed(self: Self, seed: anytype) Return(@TypeOf(seed)) {
                return try nextElementSeed(self.context, seed);
            }

            pub fn nextElement(self: Self, comptime Value: type) Error!?Value {
                var seed = getty.de.DefaultSeed(Value){};
                const ds = seed.seed();

                return try self.nextElementSeed(ds);
            }

            fn Return(comptime Seed: type) type {
                comptime getty.concepts.@"getty.de.Seed"(Seed);

                return Error!?Seed.Value;
            }
        };

        pub fn seq(self: Context) @"getty.de.Seq" {
            return .{ .context = self };
        }
    };
}
