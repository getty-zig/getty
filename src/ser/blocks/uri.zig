const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return T == std.Uri;
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
        const str = try std.fmt.allocPrint(a, "{+/#}", .{value});
        defer a.free(str);

        return try serializer.serializeString(str);
    }

    return error.MissingAllocator;
}

test "serialize - std.Uri" {
    // RFC example 1
    {
        const uri = std.Uri{
            .scheme = "foo",
            .user = null,
            .password = null,
            .host = "example.com",
            .port = 8042,
            .path = "/over/there",
            .query = "name=ferret",
            .fragment = "nose",
        };

        t.run(std.testing.allocator, serialize, uri, &.{.{ .String = "foo://example.com:8042/over/there?name=ferret#nose" }}) catch return error.UnexpectedTestError;
    }

    // RFC example 2
    {
        const uri = std.Uri{
            .scheme = "urn",
            .user = null,
            .password = null,
            .host = null,
            .port = null,
            .path = "example:animal:ferret:nose",
            .query = null,
            .fragment = null,
        };

        t.run(std.testing.allocator, serialize, uri, &.{.{ .String = "urn:example:animal:ferret:nose" }}) catch return error.UnexpectedTestError;
    }
}
