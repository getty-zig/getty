const getty = @import("../../lib.zig");
const std = @import("std");

pub fn VariantAccess(
    comptime Context: type,
    comptime Error: type,
    comptime voidVariant: fn (Context) Error!void,
    comptime variant: @TypeOf(struct {
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
            pub const Variant = Variant;

            pub fn voidVariant(self: Self) Error!void {
                return try voidVariant(self.context);
            }

            pub fn variant(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(Error, @TypeOf(seed)) {
                return try variant(self.context, allocator, seed);
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
