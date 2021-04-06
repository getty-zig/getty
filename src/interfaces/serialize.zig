const std = @import("std");
const attr = @import("detail/attribute.zig");

pub fn Serialize(comptime T: type, attr_map: anytype) type {
    attr.check_attributes(T, attr_map, .Ser);

    return struct {
        pub fn serialize(self: T) !void {
            std.debug.print("Serialize!\n", .{});
        }
    };
}

const expect = std.testing.expect;

test "Serialize - basic (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{});

        x: i32,
        y: i32,
    };
}

test "Serialize - with container attribute (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{ .T = .{ .rename = "A" } });

        x: i32,
        y: i32,
    };
}

test "Serialize - with field attribute (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{ .x = .{ .rename = "a" } });

        x: i32,
        y: i32,
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
