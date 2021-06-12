const std = @import("std");
const getty_json = @import("getty").json;

const expectEqualSlices = std.testing.expectEqualSlices;
const String = std.ArrayList(u8);

test "array" {
    var array_list = String.init(std.testing.allocator);
    defer array_list.deinit();

    try getty_json.toWriter(array_list.writer(), [_]u8{ 1, 2, 3 });
    try expectEqualSlices(u8, array_list.items, "[1,2,3]");
}

test "bool" {
    {
        var array_list = String.init(std.testing.allocator);
        defer array_list.deinit();
        try getty_json.toWriter(array_list.writer(), true);
        try expectEqualSlices(u8, array_list.items, "true");
    }

    {
        var array_list = String.init(std.testing.allocator);
        defer array_list.deinit();
        try getty_json.toWriter(array_list.writer(), false);
        try expectEqualSlices(u8, array_list.items, "false");
    }
}

test "int" {
    {
        var array_list = String.init(std.testing.allocator);
        defer array_list.deinit();

        try getty_json.toWriter(array_list.writer(), 'A');
        try expectEqualSlices(u8, array_list.items, "65");
    }

    {
        var array_list = String.init(std.testing.allocator);
        defer array_list.deinit();

        try getty_json.toWriter(array_list.writer(), std.math.maxInt(u32));
        try expectEqualSlices(u8, array_list.items, "4294967295");
    }

    {
        var array_list = String.init(std.testing.allocator);
        defer array_list.deinit();

        try getty_json.toWriter(array_list.writer(), std.math.maxInt(u64));
        try expectEqualSlices(u8, array_list.items, "18446744073709551615");
    }

    {
        var array_list = String.init(std.testing.allocator);
        defer array_list.deinit();

        try getty_json.toWriter(array_list.writer(), std.math.minInt(i32));
        try expectEqualSlices(u8, array_list.items, "-2147483648");
    }
}

test "null" {
    var array_list = String.init(std.testing.allocator);
    defer array_list.deinit();

    try getty_json.toWriter(array_list.writer(), null);
    try expectEqualSlices(u8, array_list.items, "null");
}

test "string" {
    var array_list = String.init(std.testing.allocator);
    defer array_list.deinit();

    try getty_json.toWriter(array_list.writer(), "Hello, World!");
    try expectEqualSlices(u8, array_list.items, "\"Hello, World!\"");
}

test "struct" {
    var array_list = String.init(std.testing.allocator);
    defer array_list.deinit();

    const Point = struct { x: i32, y: i32 };
    var point = Point{ .x = 1, .y = 2 };

    try getty_json.toWriter(array_list.writer(), point);

    try expectEqualSlices(u8, array_list.items, "{\"x\":1,\"y\":2}");
}

test "enum" {
    var array_list = String.init(std.testing.allocator);
    defer array_list.deinit();

    try getty_json.toWriter(array_list.writer(), enum { Foo }.Foo);
    try expectEqualSlices(u8, array_list.items, "\"Foo\"");
}

test "enum literal" {
    var array_list = String.init(std.testing.allocator);
    defer array_list.deinit();

    try getty_json.toWriter(array_list.writer(), .Foo);
    try expectEqualSlices(u8, array_list.items, "\"Foo\"");
}
