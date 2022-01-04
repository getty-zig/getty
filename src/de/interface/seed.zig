const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

pub fn Seed(
    comptime Context: type,
    comptime Value: type,
    comptime deserialize: @TypeOf(struct {
        fn f(c: Context, a: ?std.mem.Allocator, d: anytype) @TypeOf(d).Error!Value {
            _ = c;
            _ = a;

            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.Seed" = struct {
            context: Context,

            const Self = @This();

            pub const Value = Value;

            pub fn deserialize(self: Self, allocator: ?std.mem.Allocator, deserializer: anytype) Return(@TypeOf(deserializer)) {
                return try deserialize(self.context, allocator, deserializer);
            }
        };

        pub fn seed(self: Context) @"getty.de.Seed" {
            return .{ .context = self };
        }

        fn Return(comptime Deserializer: type) type {
            comptime concepts.@"getty.Deserializer"(Deserializer);

            return Deserializer.Error!Value;
        }
    };
}
