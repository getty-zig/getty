const std = @import("std");

pub fn Deserialize(comptime Context: type, deserialize_fn: fn (context: Context, deserializer: Deserializer) !void) type {
    return struct {
        const Self = @This();

        context: Context,

        pub fn deserialize(self: Self, deserializer: Deserializer) !void {
            return try deserialize_fn(self.context, deserializer);
        }
    };
}

pub fn Deserializer(
    comptime Context: type,
) type {
    return struct {
        const Self = @This();

        context: Context,
    };
}

test "Deserialize - init" {
    const Point = struct {
        x: i32,
        y: i32,
    };
}
