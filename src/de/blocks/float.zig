const std = @import("std");

const FloatVisitor = @import("../impls/visitor/float.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => true,
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

    return try deserializer.deserializeFloat(result_ally, scratch_ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return FloatVisitor(T);
}

test "deserialize - float" {
    const tests = .{
        .{
            .name = "f16",
            .tokens = &.{.{ .F16 = 0 }},
            .want = @as(f16, 0),
        },
        .{
            .name = "f32",
            .tokens = &.{.{ .F32 = 0 }},
            .want = @as(f32, 0),
        },
        .{
            .name = "f64",
            .tokens = &.{.{ .F64 = 0 }},
            .want = @as(f64, 0),
        },
        .{
            .name = "f128",
            .tokens = &.{.{ .F128 = 0 }},
            .want = @as(f128, 0),
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want, result.value);
    }
}
