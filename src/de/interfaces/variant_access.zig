const getty = @import("../../lib.zig");
const std = @import("std");

pub fn VariantAccess(
    comptime Context: type,
    comptime Error: type,
    comptime payloadSeed: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) Return(Error, @TypeOf(seed)) {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.VariantAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = Error;

            pub fn payloadSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(Error, @TypeOf(seed)) {
                return try payloadSeed(self.context, allocator, seed);
            }

            pub fn payload(self: Self, allocator: ?std.mem.Allocator, comptime T: type) Error!T {
                var ds = getty.de.DefaultSeed(T){};
                const seed = ds.seed();

                return try self.payloadSeed(allocator, seed);
            }
        };

        pub fn variantAccess(self: Context) @"getty.de.VariantAccess" {
            return .{ .context = self };
        }
    };
}

fn Return(comptime Error: type, comptime Seed: type) type {
    comptime getty.concepts.@"getty.de.Seed"(Seed);

    return Error!Seed.Value;
}
