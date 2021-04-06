const std = @import("std");
const attr = @import("detail/attribute.zig");

pub fn Serialize(comptime T: type, attribute_map: anytype) type {
    attr.check_attributes(T, attribute_map, .Serialize);

    return struct {
        pub fn serialize(self: T) !void {
            std.debug.print("Serialize!\n", .{});
        }
    };
}

test "Basic" {
    const Test = struct {
        usingnamespace Serialize(
            @This(),
            .{
                .Test = .{ .rename = "Foo" },
                .x = .{ .rename = "a" },
                .y = .{ .rename = "b" },
            },
        );

        x: i32,
        y: i32,
    };
}
