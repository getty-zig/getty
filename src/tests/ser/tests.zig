const std = @import("std");
const getty = @import("getty");

const Token = @import("token.zig").Token;
const Serializer = @import("serializer.zig").Serializer;

const allocator = std.testing.allocator;

test "array" {
    try t([_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });
    try t([_]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = .{} },
    });
}

test "array list" {
    // managed
    {
        var list = std.ArrayList(std.ArrayList(i32)).init(allocator);
        defer list.deinit();

        var a = std.ArrayList(i32).init(allocator);
        defer a.deinit();

        var b = std.ArrayList(i32).init(allocator);
        defer b.deinit();

        var c = std.ArrayList(i32).init(allocator);
        defer c.deinit();

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
        });

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try list.appendSlice(&[_]std.ArrayList(i32){ a, b, c });

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = .{} },
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = .{} },
            .{ .SeqEnd = .{} },
        });
    }

    // unmanaged
    {
        var list = std.ArrayListUnmanaged(std.ArrayListUnmanaged(i32)){};
        defer list.deinit(allocator);

        var a = std.ArrayListUnmanaged(i32){};
        defer a.deinit(allocator);

        var b = std.ArrayListUnmanaged(i32){};
        defer b.deinit(allocator);

        var c = std.ArrayListUnmanaged(i32){};
        defer c.deinit(allocator);

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
        });

        try b.append(allocator, 1);
        try c.append(allocator, 2);
        try c.append(allocator, 3);
        try list.appendSlice(allocator, &[_]std.ArrayListUnmanaged(i32){ a, b, c });

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = .{} },
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = .{} },
            .{ .SeqEnd = .{} },
        });
    }
}

test "bool" {
    try t(true, &[_]Token{.{ .Bool = true }});
    try t(false, &[_]Token{.{ .Bool = false }});
}

test "enum" {
    // enum literal
    try t(.Foo, &[_]Token{.{ .Enum = .{ .name = "", .variant = "Foo" } }});

    // enum
    const Enum = enum { Foo, Bar };
    try t(Enum.Foo, &[_]Token{.{ .Enum = .{ .name = "Enum", .variant = "Foo" } }});
    try t(Enum.Bar, &[_]Token{.{ .Enum = .{ .name = "Enum", .variant = "Bar" } }});
}

test "error" {
    try t(error.Foobar, &[_]Token{.{ .String = "Foobar" }});
}

test "float" {
    // comptime_float
    try t(0.0, &[_]Token{.{ .ComptimeFloat = {} }});

    // float
    try t(@as(f16, 0), &[_]Token{.{ .F16 = 0 }});
    try t(@as(f32, 0), &[_]Token{.{ .F32 = 0 }});
    try t(@as(f64, 0), &[_]Token{.{ .F64 = 0 }});
}

test "hash map" {
    // managed
    {
        var map = std.AutoHashMap(i32, i32).init(allocator);
        defer map.deinit();

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = .{} },
        });

        try map.put(1, 2);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = .{} },
        });
    }

    // unmanaged
    {
        var map = std.AutoHashMapUnmanaged(i32, i32){};
        defer map.deinit(allocator);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = .{} },
        });

        try map.put(allocator, 1, 2);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = .{} },
        });
    }

    // string
    {
        var map = std.StringHashMap(i32).init(allocator);
        defer map.deinit();

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = .{} },
        });

        try map.put("1", 2);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 1 } },
            .{ .String = "1" },
            .{ .I32 = 2 },
            .{ .MapEnd = .{} },
        });
    }
}

test "integer" {
    // comptime_int
    try t(0, &[_]Token{.{ .ComptimeInt = {} }});

    // signed
    try t(@as(i8, 0), &[_]Token{.{ .I8 = 0 }});
    try t(@as(i16, 0), &[_]Token{.{ .I16 = 0 }});
    try t(@as(i32, 0), &[_]Token{.{ .I32 = 0 }});
    try t(@as(i64, 0), &[_]Token{.{ .I64 = 0 }});

    // unsigned
    try t(@as(u8, 0), &[_]Token{.{ .U8 = 0 }});
    try t(@as(u16, 0), &[_]Token{.{ .U16 = 0 }});
    try t(@as(u32, 0), &[_]Token{.{ .U32 = 0 }});
    try t(@as(u64, 0), &[_]Token{.{ .U64 = 0 }});
}

test "linked list" {
    var list = std.SinglyLinkedList(i32){};

    try t(list, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });

    var one = @TypeOf(list).Node{ .data = 1 };
    var two = @TypeOf(list).Node{ .data = 2 };
    var three = @TypeOf(list).Node{ .data = 3 };

    list.prepend(&one);
    one.insertAfter(&two);
    two.insertAfter(&three);

    try t(list, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = .{} },
    });
}

test "null" {
    try t(null, &[_]Token{.{ .Null = {} }});
}

test "optional" {
    try t(@as(?i32, null), &[_]Token{.{ .Null = {} }});
    try t(@as(?i32, 0), &[_]Token{ .{ .Some = {} }, .{ .I32 = 0 } });
}

test "pointer" {

    // one level of indirection
    {
        var ptr = try allocator.create(i32);
        defer allocator.destroy(ptr);
        ptr.* = @as(i32, 1);

        try t(ptr, &[_]Token{.{ .I32 = 1 }});
    }

    // two levels of indirection
    {
        var tmp = try allocator.create(i32);
        defer allocator.destroy(tmp);
        tmp.* = 2;

        var ptr = try allocator.create(*i32);
        defer allocator.destroy(ptr);
        ptr.* = tmp;

        try t(ptr, &[_]Token{.{ .I32 = 2 }});
    }

    // pointer to slice
    {
        var ptr = try allocator.create([]const u8);
        defer allocator.destroy(ptr);
        ptr.* = "3";

        try t(ptr, &[_]Token{.{ .String = "3" }});
    }
}

test "slice" {
    try t(&[_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });
    try t(&[_]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = .{} },
    });
}

test "string" {
    try t("abc", &[_]Token{.{ .String = "abc" }});
    try t(&[_]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    try t(&[_:0]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    try t(&[_]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    try t(&[_:0]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
}

test "struct" {
    const Struct = struct { a: i32, b: i32, c: i32 };

    try t(Struct{ .a = 1, .b = 2, .c = 3 }, &[_]Token{
        .{ .Struct = .{ .name = "Struct", .len = 3 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .String = "c" },
        .{ .I32 = 3 },
        .{ .StructEnd = {} },
    });
}

test "tail queue" {
    var list = std.TailQueue(i32){};

    try t(list, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });

    var one = @TypeOf(list).Node{ .data = 1 };
    var two = @TypeOf(list).Node{ .data = 2 };
    var three = @TypeOf(list).Node{ .data = 3 };

    list.append(&one);
    list.append(&two);
    list.append(&three);

    try t(list, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = .{} },
    });
}

test "tuple" {
    try t(.{}, &[_]Token{
        .{ .Tuple = .{ .len = 0 } },
        .{ .TupleEnd = .{} },
    });

    try t(std.meta.Tuple(&[_]type{ i32, bool }){ 1, true }, &[_]Token{
        .{ .Tuple = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .Bool = true },
        .{ .TupleEnd = .{} },
    });

    try t(.{ @as(i32, 1), true }, &[_]Token{
        .{ .Tuple = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .Bool = true },
        .{ .TupleEnd = .{} },
    });
}

test "union" {
    const Union = union(enum) { Int: i32, Bool: bool };

    try t(Union{ .Int = 0 }, &[_]Token{.{ .I32 = 0 }});
    try t(Union{ .Bool = true }, &[_]Token{.{ .Bool = true }});
}

test "vector" {
    try t(@splat(2, @as(i32, 1)), &[_]Token{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .I32 = 1 },
        .{ .SeqEnd = {} },
    });
}

test "void" {
    try t({}, &[_]Token{.{ .Void = {} }});
}

fn t(v: anytype, tokens: []const Token) !void {
    var s = Serializer.init(tokens);

    getty.serialize(v, s.serializer()) catch return error.TestUnexpectedError;
    try std.testing.expect(s.remaining() == 0);
}
