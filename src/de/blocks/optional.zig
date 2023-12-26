const require = @import("protest").require;
const std = @import("std");

const OptionalVisitor = @import("../impls/visitor/optional.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Optional;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeOptional(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return OptionalVisitor(T);
}

test "deserialize - optional" {
    const tests = .{
        .{
            .name = "null",
            .tokens = &.{.{ .Null = {} }},
            .want = @as(?i32, null),
        },
        .{
            .name = "non-null",
            .tokens = &.{ .{ .Some = {} }, .{ .I32 = 0 } },
            .want = @as(?i32, 0),
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try require.equal(t.want, result.value);
    }
}
