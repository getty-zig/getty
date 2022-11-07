const std = @import("std");

const de = @import("../../de.zig");

pub fn UnionAccess(
    comptime Context: type,
    comptime E: type,
    comptime variantSeedFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) Return(E, @TypeOf(seed)) {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.UnionAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn variantSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(Error, @TypeOf(seed)) {
                return try variantSeedFn(self.context, allocator, seed);
            }

            pub fn variant(self: Self, allocator: ?std.mem.Allocator, comptime T: type) Error!T {
                var ds = de.de.DefaultSeed(T){};
                const seed = ds.seed();

                return try self.variantSeed(allocator, seed);
            }
        };

        pub fn unionAccess(self: Context) @"getty.de.UnionAccess" {
            return .{ .context = self };
        }
    };
}

fn Return(comptime Error: type, comptime Seed: type) type {
    comptime de.concepts.@"getty.de.Seed"(Seed);

    return Error!Seed.Value;
}
