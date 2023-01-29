const std = @import("std");

const EnumVisitor = @import("../impls/visitor/enum.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Enum;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeEnum(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return EnumVisitor(T);
}

test "deserialize - enum" {
    const T = enum { zero, one, two, three, four };

    const tests = .{
        .{
            .name = "from integer, u8",
            .tokens = &.{ .{ .Enum = {} }, .{ .U8 = 0 } },
            .want = T.zero,
        },
        .{
            .name = "from integer, u16",
            .tokens = &.{ .{ .Enum = {} }, .{ .U16 = 1 } },
            .want = T.one,
        },
        .{
            .name = "from integer, u32",
            .tokens = &.{ .{ .Enum = {} }, .{ .U32 = 2 } },
            .want = T.two,
        },
        .{
            .name = "from integer, u64",
            .tokens = &.{ .{ .Enum = {} }, .{ .U64 = 3 } },
            .want = T.three,
        },
        .{
            .name = "from integer, u128",
            .tokens = &.{ .{ .Enum = {} }, .{ .U128 = 4 } },
            .want = T.four,
        },
        .{
            .name = "from string (I)",
            .tokens = &.{ .{ .Enum = {} }, .{ .String = "zero" } },
            .want = T.zero,
        },
        .{
            .name = "from string (II)",
            .tokens = &.{ .{ .Enum = {} }, .{ .String = "four" } },
            .want = T.four,
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);
        try testing.expectEqual(t.name, t.want, got);
    }
}
