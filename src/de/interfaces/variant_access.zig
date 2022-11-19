const std = @import("std");

const de = @import("../../de.zig");

pub fn VariantAccess(
    comptime Context: type,
    comptime E: type,
    comptime methods: struct {
        payloadSeed: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) Return(E, @TypeOf(seed)) {
                unreachable;
            }
        }.f) = null,

        // Provided method.
        payload: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime T: type) E!T {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        pub const @"getty.de.VariantAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn payloadSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(Error, @TypeOf(seed)) {
                if (methods.payloadSeed) |f| {
                    return try f(self.context, allocator, seed);
                }

                @compileError("payloadSeed is not implemented by type: " ++ @typeName(Context));
            }

            pub fn payload(self: Self, allocator: ?std.mem.Allocator, comptime T: type) Error!T {
                if (methods.payload) |f| {
                    return try f(self.context, allocator, T);
                } else {
                    var ds = de.de.DefaultSeed(T){};
                    const seed = ds.seed();

                    return try self.payloadSeed(allocator, seed);
                }
            }
        };

        pub fn variantAccess(self: Context) @"getty.de.VariantAccess" {
            return .{ .context = self };
        }
    };
}

fn Return(comptime Error: type, comptime Seed: type) type {
    comptime de.concepts.@"getty.de.Seed"(Seed);

    return Error!Seed.Value;
}
