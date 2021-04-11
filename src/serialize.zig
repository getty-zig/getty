const std = @import("std");

pub fn Serialize(comptime Context: type, serialize_fn: fn (context: Context, serializer: Serializer) !void) type {
    return struct {
        const Self = @This();

        context: Context,

        pub fn serialize(self: Self, serializer: Serializer) !void {
            return try serialize_fn(self.context, serializer);
        }
    };
}

pub fn Serializer(
    comptime Context: type,
    serialize_bool_fn: fn (context: Context, v: bool) !void,
) type {
    return struct {
        const Self = @This();

        context: Context,

        pub fn serialize_bool(self: Self, v: bool) !void {
            return try serialize_bool_fn(self.context, v);
        }
    };
}

test "Serialize - init" {
    const Point = struct {
        x: i32,
        y: i32,
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
