const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return T == std.SemanticVersion;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    if (ally) |a| {
        const str = try std.fmt.allocPrint(a, "{}", .{value});
        defer a.free(str);

        return try serializer.serializeString(str);
    }

    return error.MissingAllocator;
}

test "serialize - std.SemanticVersion" {
    // Normal
    {
        const version = std.SemanticVersion{
            .major = 1,
            .minor = 2,
            .patch = 3,
        };

        t.run(std.testing.allocator, serialize, version, &.{.{ .String = "1.2.3" }}) catch return error.UnexpectedTestError;
    }

    // Pre
    {
        const version = std.SemanticVersion{
            .major = 1,
            .minor = 2,
            .patch = 3,
            .pre = "alpha",
        };

        t.run(std.testing.allocator, serialize, version, &.{.{ .String = "1.2.3-alpha" }}) catch return error.UnexpectedTestError;
    }

    // Build
    {
        const version = std.SemanticVersion{
            .major = 1,
            .minor = 2,
            .patch = 3,
            .build = "build.1",
        };

        t.run(std.testing.allocator, serialize, version, &.{.{ .String = "1.2.3+build.1" }}) catch return error.UnexpectedTestError;
    }

    // Pre & Build
    {
        const version = std.SemanticVersion{
            .major = 1,
            .minor = 2,
            .patch = 3,
            .pre = "alpha",
            .build = "build.1",
        };

        t.run(std.testing.allocator, serialize, version, &.{.{ .String = "1.2.3-alpha+build.1" }}) catch return error.UnexpectedTestError;
    }
}
