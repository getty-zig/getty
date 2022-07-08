const getty = @import("../../lib.zig");
const std = @import("std");

pub fn SeqAccess(
    comptime Context: type,
    comptime Error: type,
    comptime nextElementSeed: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.SeqAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = Error;

            pub fn nextElementSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(@TypeOf(seed)) {
                return try nextElementSeed(self.context, allocator, seed);
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
