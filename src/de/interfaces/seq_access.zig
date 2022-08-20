const getty = @import("../../lib.zig");
const std = @import("std");

pub fn SeqAccess(
    comptime Context: type,
    comptime E: type,
    comptime nextElementSeedFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.SeqAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn nextElementSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(@TypeOf(seed)) {
                return try nextElementSeedFn(self.context, allocator, seed);
            }

            pub fn nextElement(self: Self, allocator: ?std.mem.Allocator, comptime Value: type) Error!?Value {
                var seed = getty.de.DefaultSeed(Value){};
                const ds = seed.seed();

                return try self.nextElementSeed(allocator, ds);
            }

            fn Return(comptime Seed: type) type {
                comptime getty.concepts.@"getty.de.Seed"(Seed);

                return Error!?Seed.Value;
            }
        };

        pub fn seqAccess(self: Context) @"getty.de.SeqAccess" {
            return .{ .context = self };
        }
    };
}
