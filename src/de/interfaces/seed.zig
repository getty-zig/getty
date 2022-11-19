const std = @import("std");

const de = @import("../../de.zig");

pub fn Seed(
    comptime Context: type,
    comptime V: type,
    comptime methods: struct {
        deserialize: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        pub const @"getty.de.Seed" = struct {
            context: Context,

            const Self = @This();

            pub const Value = V;

            pub fn deserialize(self: Self, allocator: ?std.mem.Allocator, deserializer: anytype) Return(@TypeOf(deserializer)) {
                if (methods.deserialize) |f| {
                    return try f(self.context, allocator, deserializer);
                }

                @compileError("deserialize is not implemented by type: " ++ @typeName(Context));
            }
        };

        pub fn seed(self: Context) @"getty.de.Seed" {
            return .{ .context = self };
        }

        fn Return(comptime Deserializer: type) type {
            comptime de.concepts.@"getty.Deserializer"(Deserializer);

            return Deserializer.Error!V;
        }
    };
}
