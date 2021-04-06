const std = @import("std");
const attr = @import("detail/attribute.zig");

pub fn Deserialize(comptime T: type, attr_map: anytype) type {
    attr.check_attributes(T, attr_map, .De);

    return struct {
        pub fn deserialize(self: T) !void {
            std.debug.print("Deserialize!\n", .{});
        }
    };
}

const expect = std.testing.expect;

test "Deserialize - basic (struct)" {
    const T = struct {
        usingnamespace Deserialize(@This(), .{});

        x: i32,
        y: i32,
    };
}

test "Deserialize - with container attribute (struct)" {
    const T = struct {
        usingnamespace Deserialize(@This(), .{ .T = .{ .rename = "A" } });

        x: i32,
        y: i32,
    };
}

test "Deserialize - with field attribute (struct)" {
    const T = struct {
        usingnamespace Deserialize(@This(), .{ .x = .{ .rename = "a" } });

        x: i32,
        y: i32,
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
