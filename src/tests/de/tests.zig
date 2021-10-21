const std = @import("std");
const getty = @import("getty");

const Deserializer = @import("deserializer.zig").Deserializer;
const Token = @import("common/token.zig").Token;

const allocator = std.testing.allocator;

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

    //// unsigned
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
    //try t([]const u8, "abc", &[_]Token{.{ .String = "abc" }});
    //try t([]const u8, &[_]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    //try t([]const u8, &[_:0]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    //try t([]const u8, &[_]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    //try t([]const u8, &[_:0]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
}

fn t(comptime T: type, expected: T, tokens: []const Token) !void {
    var d = Deserializer.init(tokens);

    const v = getty.deserialize(
        allocator,
        T,
        d.deserializer(),
    ) catch return error.TestUnexpectedError;

    // TODO: Handle slices, structs, etc.
    try std.testing.expectEqual(v, expected);
    try std.testing.expect(d.remaining() == 0);
}
