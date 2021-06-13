const std = @import("std");
const getty_json = @import("getty").json;

const expectEqualSlices = std.testing.expectEqualSlices;
const String = std.ArrayList(u8);

test "toWriter" {
    const test_cases = [_]struct { input: anytype, output: []const u8 }{
        // Bool
        .{ .input = true, .output = "true" },
        .{ .input = false, .output = "false" },

        // Integer
        .{ .input = 'A', .output = "65" },
        .{ .input = comptime std.math.maxInt(u32), .output = "4294967295" },
        .{ .input = comptime std.math.maxInt(u64), .output = "18446744073709551615" },
        .{ .input = comptime std.math.minInt(i32), .output = "-2147483648" },

        // Null
        .{ .input = null, .output = "null" },

        // String
        .{ .input = "Hello, World!", .output = "\"Hello, World!\"" },

        // Enum
        .{ .input = enum { Foo }.Foo, .output = "\"Foo\"" },
        .{ .input = .Foo, .output = "\"Foo\"" },
    };

    inline for (test_cases) |t| {
        var array_list = String.init(std.testing.allocator);
        defer array_list.deinit();

        try getty_json.toWriter(array_list.writer(), t.input);
        try expectEqualSlices(u8, array_list.items, t.output);
    }
}

// FIXME: Merge into test "toWriter" blocked by #5877.
test "toWriter - array" {
    var array_list = String.init(std.testing.allocator);
    defer array_list.deinit();

    try getty_json.toWriter(array_list.writer(), [_]u8{ 1, 2, 3 });
    try expectEqualSlices(u8, array_list.items, "[1,2,3]");
}

// FIXME: Merge into test "toWriter" blocked by #5877.
test "toWriter - struct" {
    var array_list = String.init(std.testing.allocator);
    defer array_list.deinit();

    const Point = struct { x: i32, y: i32 };
    var point = Point{ .x = 1, .y = 2 };

    try getty_json.toWriter(array_list.writer(), point);

    try expectEqualSlices(u8, array_list.items, "{\"x\":1,\"y\":2}");
}
