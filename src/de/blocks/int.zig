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
    /// A memory allocator for heap values that are part of the returned
    /// deserialized value.
    result_ally: std.mem.Allocator,
    /// A memory allocator for heap values that are not part of the returned
    /// deserialized value.
    scratch_ally: std.mem.Allocator,
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
        .{
            .name = "i32 -> i8",
            .tokens = &.{.{ .I32 = std.math.maxInt(i8) }},
            .want = @as(i8, std.math.maxInt(i8)),
        },
        .{
            .name = "i32 -> u8",
            .tokens = &.{.{ .I32 = std.math.maxInt(u8) }},
            .want = @as(u8, std.math.maxInt(u8)),
        },
        .{
            .name = "i32 -> u32",
            .tokens = &.{.{ .I32 = std.math.maxInt(i32) }},
            .want = @as(u32, std.math.maxInt(i32)),
        },
        .{
            .name = "u32 -> u8",
            .tokens = &.{.{ .U32 = std.math.maxInt(u8) }},
            .want = @as(u8, std.math.maxInt(u8)),
        },
        .{
            .name = "u32 -> i8",
            .tokens = &.{.{ .U32 = std.math.maxInt(i8) }},
            .want = @as(i8, std.math.maxInt(i8)),
        },
        .{
            .name = "u32 -> i32",
            .tokens = &.{.{ .U32 = std.math.maxInt(i32) }},
            .want = @as(i32, std.math.maxInt(i32)),
        },
        .{
            .name = "i32 -> i8 (fail)",
            .tokens = &.{.{ .I32 = std.math.maxInt(i32) }},
            .Want = i8,
            .want_err = error.Overflow,
        },
        .{
            .name = "i32 -> u8 (fail)",
            .tokens = &.{.{ .I32 = std.math.minInt(i32) }},
            .Want = u8,
            .want_err = error.Overflow,
        },
        .{
            .name = "i32 -> u32 (fail)",
            .tokens = &.{.{ .I32 = std.math.minInt(i32) }},
            .Want = u32,
            .want_err = error.Overflow,
        },
        .{
            .name = "u32 -> u8 (fail)",
            .tokens = &.{.{ .U32 = std.math.maxInt(u32) }},
            .Want = u8,
            .want_err = error.Overflow,
        },
        .{
            .name = "u32 -> i8 (fail)",
            .tokens = &.{.{ .U32 = std.math.maxInt(u32) }},
            .Want = i8,
            .want_err = error.Overflow,
        },
        .{
            .name = "u32 -> i32 (fail)",
            .tokens = &.{.{ .U32 = std.math.maxInt(u32) }},
            .Want = i32,
            .want_err = error.Overflow,
        },
    };

    inline for (tests) |t| {
        const Test = @TypeOf(t);
        const Want = if (@hasField(Test, "Want")) t.Want else @TypeOf(t.want);

        if (@hasField(Test, "want_err")) {
            try testing.expectError(
                t.name,
                t.want_err,
                testing.deserializeErr(Self, Want, t.tokens),
            );
        } else {
            var result = try testing.deserialize(t.name, Self, Want, t.tokens);
            defer result.deinit();

            try testing.expectEqual(t.name, t.want, result.value);
        }
    }
}

test "deserialize - integer (from string)" {
    const tests = .{
        .{
            .name = "signed",
            .tokens = &.{.{ .String = "127" }},
            .want = @as(i8, std.math.maxInt(i8)),
        },
        .{
            .name = "unsigned",
            .tokens = &.{.{ .String = "255" }},
            .want = @as(u8, std.math.maxInt(u8)),
        },
        .{
            .name = "overflow",
            .tokens = &.{.{ .String = "128" }},
            .Want = i8,
            .want_err = error.InvalidValue,
        },
        .{
            .name = "underflow",
            .tokens = &.{.{ .String = "-1" }},
            .Want = u8,
            .want_err = error.InvalidValue,
        },
    };

    inline for (tests) |t| {
        const Test = @TypeOf(t);
        const Want = if (@hasField(Test, "Want")) t.Want else @TypeOf(t.want);

        if (@hasField(Test, "want_err")) {
            try testing.expectError(
                t.name,
                t.want_err,
                testing.deserializeErr(Self, Want, t.tokens),
            );
        } else {
            var result = try testing.deserialize(t.name, Self, Want, t.tokens);
            defer result.deinit();

            try testing.expectEqual(t.name, t.want, result.value);
        }
    }
}
