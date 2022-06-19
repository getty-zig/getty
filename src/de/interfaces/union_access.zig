const getty = @import("../../lib.zig");
const std = @import("std");

pub fn UnionAccess(
    comptime Context: type,
    comptime Error: type,
    comptime Variant: type,
    comptime variantSeed: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) Return(Error, Variant, @TypeOf(seed)) {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.UnionAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = Error;
            pub const Variant = Variant;

            pub fn variantSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(Error, Variant, @TypeOf(seed)) {
                return try variantSeed(self.context, allocator, seed);
            }

            //pub fn variant(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(Error, Variant, @TypeOf(seed)) {
            //return try variantSeed(self.context, allocator, seed);
            //}
        };

        pub fn unionAccess(self: Context) @"getty.de.UnionAccess" {
            return .{ .context = self };
        }
    };
}

fn Return(comptime Error: type, comptime Variant: type, comptime Seed: type) type {
    comptime getty.concepts.@"getty.de.Seed"(Seed);

    return Error!std.meta.Tuple(&[_]type{ Seed.Value, Variant });
}
