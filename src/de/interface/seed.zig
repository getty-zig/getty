const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

pub fn Seed(
    comptime Context: type,
    comptime Value: type,
    comptime deserialize: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
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
