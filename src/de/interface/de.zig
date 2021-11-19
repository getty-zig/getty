const std = @import("std");

pub fn De(
    comptime Context: type,
    deserialize: @TypeOf(struct {
        fn f(
            self: Context,
            allocator: ?*std.mem.Allocator,
            comptime T: type,
            deserializer: anytype,
        ) @TypeOf(deserializer).Error!T {
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

            pub fn deserialize(
                self: Self,
                allocator: ?*std.mem.Allocator,
                comptime T: type,
                deserializer: anytype,
            ) @TypeOf(deserializer).Error!T {
                return try deserialize(self.context, allocator, T, deserializer);
            }
        };

        pub fn de(self: Context) @"getty.De" {
            return .{ .context = self };
        }
    };
}
