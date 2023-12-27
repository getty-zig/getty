const require = @import("protest").require;
const std = @import("std");

const UriVisitor = @import("../impls/visitor/uri.zig");
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == std.Uri;
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

    return try deserializer.deserializeString(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    _ = T;

    return UriVisitor;
}

test "deserialize - std.Uri" {
    const tests = .{
        .{
            .name = "rfc example 1",
            .tokens = &.{.{ .String = "foo://example.com:8042/over/there?name=ferret#nose" }},
            .want = std.Uri{
                .scheme = "foo",
                .user = null,
                .password = null,
                .host = "example.com",
                .port = 8042,
                .path = "/over/there",
                .query = "name=ferret",
                .fragment = "nose",
            },
        },
        .{
            .name = "rfc example 2",
            .tokens = &.{.{ .String = "urn:example:animal:ferret:nose" }},
            .want = std.Uri{
                .scheme = "urn",
                .user = null,
                .password = null,
                .host = null,
                .port = null,
                .path = "example:animal:ferret:nose",
                .query = null,
                .fragment = null,
            },
        },
    };

    inline for (tests) |t| {
        const Test = @TypeOf(t);

        if (@hasField(Test, "want_err")) {
            try require.equalError(
                t.want_err,
                testing.deserializeErr(Self, std.SemanticVersion, t.tokens),
            );
        } else {
            const Want = @TypeOf(t.want);
            var result = try testing.deserialize(t.name, Self, Want, t.tokens);
            defer result.deinit();

            try require.equalf(t.want.scheme, result.value.scheme, "Test case: {s}", .{t.name});
            try require.equalf(t.want.port, result.value.port, "Test case: {s}", .{t.name});
            try require.equalf(t.want.path, result.value.path, "Test case: {s}", .{t.name});

            if (t.want.host) |host| {
                try require.notNull(result.value.host);
                try require.equalf(host, result.value.host.?, "Test case: {s}", .{t.name});
            }
            if (t.want.user) |user| {
                try require.notNull(result.value.user);
                try require.equalf(user, result.value.user.?, "Test case: {s}", .{t.name});
            }
            if (t.want.password) |password| {
                try require.notNull(result.value.password);
                try require.equalf(password, result.value.password.?, "Test case: {s}", .{t.name});
            }
            if (t.want.query) |query| {
                try require.notNull(result.value.query);
                try require.equalf(query, result.value.query.?, "Test case: {s}", .{t.name});
            }
            if (t.want.fragment) |fragment| {
                try require.notNull(result.value.fragment);
                try require.equalf(fragment, result.value.fragment.?, "Test case: {s}", .{t.name});
            }
        }
    }
}
