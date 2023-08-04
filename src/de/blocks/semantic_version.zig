const std = @import("std");

const SemanticVersionVisitor = @import("../impls/visitor/semantic_version.zig");
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == std.SemanticVersion;
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

    return try deserializer.deserializeString(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    _ = T;

    return SemanticVersionVisitor;
}

/// Frees resources allocated by Getty during deserialization.
pub fn free(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// A `getty.Deserializer` interface type.
    comptime _: type,
    /// A value to deallocate.
    value: anytype,
) void {
    if (value.pre) |pre| ally.free(pre);
    if (value.build) |build| ally.free(build);
}

test "deserialize - std.SemanticVersion" {
    const tests = .{
        .{
            .name = "major, minor, patch",
            .tokens = &.{.{ .String = "1.2.3" }},
            .want = std.SemanticVersion{
                .major = 1,
                .minor = 2,
                .patch = 3,
            },
        },
        .{
            .name = "pre",
            .tokens = &.{.{ .String = "1.2.3-alpha" }},
            .want = std.SemanticVersion{
                .major = 1,
                .minor = 2,
                .patch = 3,
                .pre = "alpha",
            },
        },
        .{
            .name = "build",
            .tokens = &.{.{ .String = "1.2.3+build.1" }},
            .want = std.SemanticVersion{
                .major = 1,
                .minor = 2,
                .patch = 3,
                .build = "build.1",
            },
        },
        .{
            .name = "pre + build",
            .tokens = &.{.{ .String = "1.2.3-alpha+build.1" }},
            .want = std.SemanticVersion{
                .major = 1,
                .minor = 2,
                .patch = 3,
                .pre = "alpha",
                .build = "build.1",
            },
        },
        .{
            .name = "invalid version",
            .tokens = &.{.{ .String = "foo bar" }},
            .want_err = error.InvalidValue,
        },
        .{
            .name = "invalid pre",
            .tokens = &.{.{ .String = "1.2.3-foo bar" }},
            .want_err = error.InvalidValue,
        },
        .{
            .name = "invalid build",
            .tokens = &.{.{ .String = "1.2.3-alpha+foo bar" }},
            .want_err = error.InvalidValue,
        },
    };

    inline for (tests) |t| {
        const Test = @TypeOf(t);

        if (@hasField(Test, "want_err")) {
            try testing.expectError(
                t.name,
                t.want_err,
                testing.deserializeErr(std.testing.allocator, Self, std.SemanticVersion, t.tokens),
            );
        } else {
            const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

            const got = try testing.deserialize(std.testing.allocator, t.name, Self, @TypeOf(t.want), t.tokens);
            defer free(std.testing.allocator, Deserializer, got);

            try testing.expectEqual(t.name, t.want.major, got.major);
            try testing.expectEqual(t.name, t.want.minor, got.minor);
            try testing.expectEqual(t.name, t.want.patch, got.patch);

            if (t.want.pre) |pre| {
                try testing.expect(t.name, got.pre != null);
                try testing.expectEqualStrings(t.name, pre, got.pre.?);
            }

            if (t.want.build) |build| {
                try testing.expect(t.name, got.build != null);
                try testing.expectEqualStrings(t.name, build, got.build.?);
            }
        }
    }
}
