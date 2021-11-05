const std = @import("std");
const getty = @import("getty");

const Deserializer = @import("deserializer.zig").Deserializer;
const Token = @import("common/token.zig").Token;

const allocator = std.testing.allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualStrings = std.testing.expectEqualStrings;

test "array" {
    try t([_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });
    try t([3]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = .{} },
    });
    try t([3][2]i32{ .{ 1, 2 }, .{ 3, 4 }, .{ 5, 6 } }, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .SeqEnd = .{} },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 3 },
        .{ .I32 = 4 },
        .{ .SeqEnd = .{} },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 5 },
        .{ .I32 = 6 },
        .{ .SeqEnd = .{} },
        .{ .SeqEnd = .{} },
    });
}

test "array list" {
    {
        var expected = std.ArrayList(void).init(allocator);
        defer expected.deinit();

        try t(expected, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
        });
    }

    {
        var expected = std.ArrayList(isize).init(allocator);
        defer expected.deinit();

        try expected.append(1);
        try expected.append(2);
        try expected.append(3);

        try t(expected, &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .I8 = 1 },
            .{ .I32 = 2 },
            .{ .I64 = 3 },
            .{ .SeqEnd = .{} },
        });
    }

    {
        const Child = std.ArrayList(isize);
        const Parent = std.ArrayList(Child);

        var expected = Parent.init(allocator);
        var a = Child.init(allocator);
        var b = Child.init(allocator);
        var c = Child.init(allocator);
        defer {
            expected.deinit();
            a.deinit();
            b.deinit();
            c.deinit();
        }

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try expected.append(a);
        try expected.append(b);
        try expected.append(c);

        const tokens = &[_]Token{
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
        };

        // Test manually since the `t` function cannot recursively test
        // user-defined containers containers without ugly hacks.
        var d = Deserializer.init(allocator, tokens);
        const v = getty.deserialize(allocator, Parent, d.deserializer()) catch return error.TestUnexpectedError;
        defer getty.de.free(allocator, v);

        try expectEqual(expected.capacity, v.capacity);
        for (v.items) |l, i| {
            try expectEqual(expected.items[i].capacity, l.capacity);
            try expectEqualSlices(isize, expected.items[i].items, l.items);
        }
    }
}

test "bool" {
    try t(true, &[_]Token{.{ .Bool = true }});
    try t(false, &[_]Token{.{ .Bool = false }});
}

test "float" {
    try t(@as(f16, 0), &[_]Token{.{ .F16 = 0 }});
    try t(@as(f32, 0), &[_]Token{.{ .F32 = 0 }});
    try t(@as(f64, 0), &[_]Token{.{ .F64 = 0 }});
    try t(@as(f128, 0), &[_]Token{.{ .F64 = 0 }});
}

test "integer" {
    // signed
    try t(@as(i8, 0), &[_]Token{.{ .I8 = 0 }});
    try t(@as(i16, 0), &[_]Token{.{ .I16 = 0 }});
    try t(@as(i32, 0), &[_]Token{.{ .I32 = 0 }});
    try t(@as(i64, 0), &[_]Token{.{ .I64 = 0 }});
    try t(@as(i128, 0), &[_]Token{.{ .I128 = 0 }});
    try t(@as(isize, 0), &[_]Token{.{ .I128 = 0 }});

    // unsigned
    try t(@as(u8, 0), &[_]Token{.{ .U8 = 0 }});
    try t(@as(u16, 0), &[_]Token{.{ .U16 = 0 }});
    try t(@as(u32, 0), &[_]Token{.{ .U32 = 0 }});
    try t(@as(u64, 0), &[_]Token{.{ .U64 = 0 }});
    try t(@as(u128, 0), &[_]Token{.{ .U128 = 0 }});
    try t(@as(usize, 0), &[_]Token{.{ .U128 = 0 }});
}

test "string" {
    try t("abc", &[_]Token{.{ .String = "abc" }});

    var arr = [_]u8{ 'a', 'b', 'c' };
    try t(&arr, &[_]Token{.{ .String = "abc" }});
    try t(@as([]const u8, &arr), &[_]Token{.{ .String = "abc" }});
}

test "tuple" {
    try t(std.meta.Tuple(&[_]type{}){}, &[_]Token{
        .{ .Tuple = .{ .len = 0 } },
        .{ .TupleEnd = .{} },
    });

    try t(std.meta.Tuple(&[_]type{ i32, u32 }){ 1, 2 }, &[_]Token{
        .{ .Tuple = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .U32 = 2 },
        .{ .TupleEnd = .{} },
    });

    try t(std.meta.Tuple(&[_]type{}){}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });

    try t(std.meta.Tuple(&[_]type{ i32, u32 }){ 1, 2 }, &[_]Token{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .U32 = 2 },
        .{ .SeqEnd = .{} },
    });

    try t(std.meta.Tuple(&[_]type{
        std.meta.Tuple(&[_]type{ i32, i32 }),
        std.meta.Tuple(&[_]type{ i32, i32 }),
        std.meta.Tuple(&[_]type{ i32, i32 }),
    }){ .{ 1, 2 }, .{ 3, 4 }, .{ 5, 6 } }, &[_]Token{
        .{ .Tuple = .{ .len = 3 } },
        .{ .Tuple = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .TupleEnd = .{} },
        .{ .Tuple = .{ .len = 2 } },
        .{ .I32 = 3 },
        .{ .I32 = 4 },
        .{ .TupleEnd = .{} },
        .{ .Tuple = .{ .len = 2 } },
        .{ .I32 = 5 },
        .{ .I32 = 6 },
        .{ .TupleEnd = .{} },
        .{ .TupleEnd = .{} },
    });
}

test "void" {
    try t({}, &[_]Token{.{ .Void = {} }});
}

/// This test function does not support recursive, user-defined containers such
/// as `std.ArrayList(std.ArrayList(u8))`.
fn t(expected: anytype, tokens: []const Token) !void {
    const T = @TypeOf(expected);

    var d = Deserializer.init(allocator, tokens);
    const v = getty.deserialize(allocator, T, d.deserializer()) catch return error.TestUnexpectedError;
    defer getty.de.free(allocator, v);

    switch (@typeInfo(T)) {
        .Bool,
        .Float,
        .Int,
        .Void,
        //.Enum,
        => try expectEqual(expected, v),
        .Array => |info| try expectEqualSlices(info.child, &expected, &v),
        .Pointer => |info| switch (comptime std.meta.trait.isZigString(T)) {
            true => try expectEqualStrings(expected, v),
            false => switch (info.size) {
                //.One => ,
                .Slice => try expectEqualSlices(info.child, expected, v),
                else => unreachable,
            },
        },
        .Struct => |info| {
            if (comptime std.mem.startsWith(u8, @typeName(T), "std.array_list")) {
                try expectEqual(expected.capacity, v.capacity);
                try expectEqualSlices(std.meta.Child(T.Slice), expected.items, v.items);
            } else switch (info.is_tuple) {
                true => {
                    const length = std.meta.fields(T).len;
                    comptime var i: usize = 0;

                    inline while (i < length) : (i += 1) {
                        try expectEqual(expected[i], v[i]);
                    }
                },
                false => unreachable, // TODO
            }
        },
        else => unreachable,
    }

    try expect(d.remaining() == 0);
}
