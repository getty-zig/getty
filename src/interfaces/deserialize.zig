const std = @import("std");
const attr = @import("detail/attribute.zig");

pub fn Deserialize(comptime T: type, attribute_map: anytype) type {
    attr.check_attributes(T, attribute_map, .Deserialize);

    return struct {
        pub fn deserialize(self: T) !void {
            std.debug.print("Deserialize!\n", .{});
        }
    };
}

test "Basic" {
    const Test = struct {
        usingnamespace Deserialize(
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
