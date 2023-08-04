const std = @import("std");

const IntVisitor = @import("../impls/visitor/int.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Int, .ComptimeInt => true,
        else => false,
    };
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeInt(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return IntVisitor(T);
}

test "deserialize - integer" {
    const tests = .{
        .{
            .name = "i8",
            .tokens = &.{.{ .I8 = 0 }},
            .want = @as(i8, 0),
        },
        .{
            .name = "i16",
            .tokens = &.{.{ .I16 = 0 }},
            .want = @as(i16, 0),
        },
        .{
            .name = "i32",
            .tokens = &.{.{ .I32 = 0 }},
            .want = @as(i32, 0),
        },
        .{
            .name = "i64",
            .tokens = &.{.{ .I64 = 0 }},
            .want = @as(i64, 0),
        },
        .{
            .name = "i128",
            .tokens = &.{.{ .I128 = 0 }},
            .want = @as(i128, 0),
        },
        .{
            .name = "isize",
            .tokens = &.{.{ .I128 = 0 }},
            .want = @as(isize, 0),
        },
        .{
            .name = "u8",
            .tokens = &.{.{ .U8 = 0 }},
            .want = @as(u8, 0),
        },
        .{
            .name = "u16",
            .tokens = &.{.{ .U16 = 0 }},
            .want = @as(u16, 0),
        },
        .{
            .name = "u32",
            .tokens = &.{.{ .U32 = 0 }},
            .want = @as(u32, 0),
        },
        .{
            .name = "u64",
            .tokens = &.{.{ .U64 = 0 }},
            .want = @as(u64, 0),
        },
        .{
            .name = "u128",
            .tokens = &.{.{ .U128 = 0 }},
            .want = @as(u128, 0),
        },
        .{
            .name = "usize",
            .tokens = &.{.{ .U128 = 0 }},
            .want = @as(usize, 0),
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);
        try testing.expectEqual(t.name, t.want, got);
    }
}
