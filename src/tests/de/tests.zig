const std = @import("std");
const getty = @import("getty");

const Deserializer = @import("deserializer.zig").Deserializer;
const Token = @import("common/token.zig").Token;

const allocator = std.testing.allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

test "array" {
    try t([0]i32, [_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });
    try t([3]i32, [3]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = .{} },
    });
    try t([3][2]i32, [3][2]i32{ .{ 1, 2 }, .{ 3, 4 }, .{ 5, 6 } }, &[_]Token{
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
    try t(std.ArrayList(isize), std.ArrayList(isize).init(allocator), &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });
}

test "bool" {
    try t(bool, true, &[_]Token{.{ .Bool = true }});
    try t(bool, false, &[_]Token{.{ .Bool = false }});
}

test "float" {
    try t(f16, @as(f16, 0), &[_]Token{.{ .F16 = 0 }});
    try t(f32, @as(f32, 0), &[_]Token{.{ .F32 = 0 }});
    try t(f64, @as(f64, 0), &[_]Token{.{ .F64 = 0 }});
    try t(f128, @as(f128, 0), &[_]Token{.{ .F64 = 0 }});
}

test "integer" {
    // signed
    try t(i8, @as(i8, 0), &[_]Token{.{ .I8 = 0 }});
    try t(i16, @as(i16, 0), &[_]Token{.{ .I16 = 0 }});
    try t(i32, @as(i32, 0), &[_]Token{.{ .I32 = 0 }});
    try t(i64, @as(i64, 0), &[_]Token{.{ .I64 = 0 }});
    try t(i128, @as(i128, 0), &[_]Token{.{ .I128 = 0 }});
    try t(isize, @as(i8, 0), &[_]Token{.{ .I8 = 0 }});
    try t(isize, @as(i16, 0), &[_]Token{.{ .I16 = 0 }});
    try t(isize, @as(i32, 0), &[_]Token{.{ .I32 = 0 }});
    try t(isize, @as(i64, 0), &[_]Token{.{ .I64 = 0 }});
    try t(isize, @as(i128, 0), &[_]Token{.{ .I128 = 0 }});

    // unsigned
    try t(u8, @as(u8, 0), &[_]Token{.{ .U8 = 0 }});
    try t(u16, @as(u16, 0), &[_]Token{.{ .U16 = 0 }});
    try t(u32, @as(u32, 0), &[_]Token{.{ .U32 = 0 }});
    try t(u64, @as(u64, 0), &[_]Token{.{ .U64 = 0 }});
    try t(u128, @as(u128, 0), &[_]Token{.{ .U128 = 0 }});
    try t(usize, @as(u8, 0), &[_]Token{.{ .U8 = 0 }});
    try t(usize, @as(u16, 0), &[_]Token{.{ .U16 = 0 }});
    try t(usize, @as(u32, 0), &[_]Token{.{ .U32 = 0 }});
    try t(usize, @as(u64, 0), &[_]Token{.{ .U64 = 0 }});
    try t(usize, @as(u128, 0), &[_]Token{.{ .U128 = 0 }});
}

test "string" {
    {
        try t([]const u8, "abc", &[_]Token{.{ .String = "abc" }});
    }

    {
        var arr = [_]u8{ 'a', 'b', 'c' };
        try t([]u8, &arr, &[_]Token{.{ .String = "abc" }});
    }
}

test "void" {
    try t(void, {}, &[_]Token{.{ .Void = {} }});
}

fn t(comptime T: type, expected: T, tokens: []const Token) !void {
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
        .Pointer => |info| switch (info.size) {
            .Slice => try expectEqualSlices(info.child, expected, v),
            else => unreachable,
        },
        .Struct => {
            if (comptime std.mem.startsWith(u8, @typeName(T), "std.array_list")) {
                try expectEqual(expected.capacity, v.capacity);
                try expectEqualSlices(std.meta.Child(T.Slice), expected.items, v.items);
            } else {
                unreachable;
            }
        },
        else => unreachable,
    }

    try expect(d.remaining() == 0);
}
