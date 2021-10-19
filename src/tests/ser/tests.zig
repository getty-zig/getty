const std = @import("std");
const getty = @import("getty");

const Token = @import("token.zig").Token;
const Serializer = @import("serializer.zig").Serializer;

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
    const allocator = std.testing.allocator;

    // managed
    {
        var list = std.ArrayList(std.ArrayList(i32)).init(allocator);
        var a = std.ArrayList(i32).init(allocator);
        var b = std.ArrayList(i32).init(allocator);
        var c = std.ArrayList(i32).init(allocator);
        defer getty.free(allocator, list);

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
        });

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try list.appendSlice(&[_]std.ArrayList(i32){ a, b, c });

        try t(list, &[_]Token{
            // START list
            .{ .Seq = .{ .len = 3 } },

            // START a
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
            // END a

            // START b
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = .{} },
            // END b

            // START c
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = .{} },
            // END c

            .{ .SeqEnd = .{} },
            // END list
        });
    }

    // unmanaged
    {
        var list = std.ArrayListUnmanaged(std.ArrayListUnmanaged(i32)){};
        var a = std.ArrayListUnmanaged(i32){};
        var b = std.ArrayListUnmanaged(i32){};
        var c = std.ArrayListUnmanaged(i32){};
        defer getty.free(allocator, list);

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
        });

        try b.append(allocator, 1);
        try c.append(allocator, 2);
        try c.append(allocator, 3);
        try list.appendSlice(allocator, &[_]std.ArrayListUnmanaged(i32){ a, b, c });

        try t(list, &[_]Token{
            // START list
            .{ .Seq = .{ .len = 3 } },

            // START a
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
            // END a

            // START b
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = .{} },
            // END b

            // START c
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = .{} },
            // END c

            .{ .SeqEnd = .{} },
            // END list
        });
    }
}

test "bool" {
    try t(true, &[_]Token{.{ .Bool = true }});
    try t(false, &[_]Token{.{ .Bool = false }});
}

test "enum" {
    // enum literal
    {
        try t(.Foo, &[_]Token{.{ .Enum = .{ .name = "", .variant = "Foo" } }});
    }

    // enum
    {
        const Enum = enum {
            Foo,
            Bar,
        };

        try t(Enum.Foo, &[_]Token{.{ .Enum = .{ .name = "Enum", .variant = "Foo" } }});
        try t(Enum.Bar, &[_]Token{.{ .Enum = .{ .name = "Enum", .variant = "Bar" } }});
    }
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
        var map = std.AutoHashMap(i32, i32).init(std.testing.allocator);
        defer getty.free(std.testing.allocator, map);

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
        defer getty.free(std.testing.allocator, map);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = .{} },
        });

        try map.put(std.testing.allocator, 1, 2);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = .{} },
        });
    }

    // string
    {
        var map = std.StringHashMap(i32).init(std.testing.allocator);
        defer getty.free(std.testing.allocator, map);

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

test "null" {
    try t(null, &[_]Token{.{ .Null = {} }});
}

test "optional" {
    try t(@as(?i32, null), &[_]Token{.{ .Null = {} }});
    try t(@as(?i32, 0), &[_]Token{ .{ .Some = {} }, .{ .I32 = 0 } });
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
test "tuple" {
    try t(.{}, &[_]Token{
        .{ .Tuple = .{ .len = 0 } },
        .{ .TupleEnd = .{} },
    });

    try t(std.meta.Tuple(&[_]type{ i32, i32, i32 }){ 1, 2, 3 }, &[_]Token{
        .{ .Tuple = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .TupleEnd = .{} },
    });

    try t(.{ @as(i32, 1), @as(i32, 2), @as(i32, 3) }, &[_]Token{
        .{ .Tuple = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .TupleEnd = .{} },
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
