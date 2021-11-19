const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

pub fn De(
    comptime Context: type,
    deserialize: @TypeOf(struct {
        fn f(self: Context, allocator: ?*std.mem.Allocator, comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
            _ = self;
            _ = allocator;
            _ = deserializer;

            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.De" = struct {
            context: Context,

            const Self = @This();

            pub fn deserialize(self: Self, allocator: ?*std.mem.Allocator, comptime T: type, deserializer: anytype) Return(T, @TypeOf(deserializer)) {
                return try deserialize(self.context, allocator, T, deserializer);
            }
        };

        pub fn de(self: Context) @"getty.De" {
            return .{ .context = self };
        }
    };
}

fn Return(comptime T: type, comptime Deserializer: type) type {
    comptime concepts.@"getty.Deserializer"(Deserializer);

    return Deserializer.Error!T;
}
