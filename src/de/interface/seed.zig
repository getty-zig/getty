const std = @import("std");

pub fn Seed(
    comptime Context: type,
    comptime Value: type,
    comptime deserialize: @TypeOf(struct {
        fn f(c: Context, a: ?*std.mem.Allocator, d: anytype) @TypeOf(d).Error!Value {
            _ = c;
            _ = a;

            unreachable;
        }
    }.f),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        pub const Value = Value;

        pub fn deserialize(
            self: Self,
            allocator: ?*std.mem.Allocator,
            deserializer: anytype,
        ) @TypeOf(deserializer).Error!Value {
            return try deserialize(self.context, allocator, deserializer);
        }
    };

    return struct {
        pub fn seed(self: Context) T {
            return .{ .context = self };
        }
    };
}
