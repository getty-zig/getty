const std = @import("std");

pub fn De(
    comptime Context: type,
    deserializeFn: @TypeOf(struct {
        fn f(self: Context, allocator: ?*std.mem.Allocator, comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
            _ = self;
            _ = allocator;
            _ = deserializer;

            unreachable;
        }
    }.f),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        pub fn deserialize(self: Self, allocator: ?*std.mem.Allocator, comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
            return try deserializeFn(self.context, allocator, T, deserializer);
        }
    };

    return struct {
        pub fn de(self: Context) T {
            return .{ .context = self };
        }
    };
}
