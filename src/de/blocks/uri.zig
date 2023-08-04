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

    return UriVisitor;
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
    ally.free(value.scheme);
    ally.free(value.path);
    if (value.host) |host| ally.free(host);
    if (value.user) |user| ally.free(user);
    if (value.password) |password| ally.free(password);
    if (value.query) |query| ally.free(query);
    if (value.fragment) |fragment| ally.free(fragment);
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
            try testing.expectError(
                t.name,
                t.want_err,
                testing.deserializeErr(std.testing.allocator, Self, std.SemanticVersion, t.tokens),
            );
        } else {
            const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

            const got = try testing.deserialize(std.testing.allocator, t.name, Self, @TypeOf(t.want), t.tokens);
            defer free(std.testing.allocator, Deserializer, got);

            try testing.expectEqualStrings(t.name, t.want.scheme, got.scheme);
            try testing.expectEqual(t.name, t.want.port, got.port);
            try testing.expectEqualStrings(t.name, t.want.path, got.path);

            if (t.want.host) |host| {
                try testing.expect(t.name, got.host != null);
                try testing.expectEqualStrings(t.name, host, got.host.?);
            }
            if (t.want.user) |user| {
                try testing.expect(t.name, got.user != null);
                try testing.expectEqualStrings(t.name, user, got.user.?);
            }
            if (t.want.password) |password| {
                try testing.expect(t.name, got.password != null);
                try testing.expectEqualStrings(t.name, password, got.password.?);
            }
            if (t.want.query) |query| {
                try testing.expect(t.name, got.query != null);
                try testing.expectEqualStrings(t.name, query, got.query.?);
            }
            if (t.want.fragment) |fragment| {
                try testing.expect(t.name, got.fragment != null);
                try testing.expectEqualStrings(t.name, fragment, got.fragment.?);
            }
        }
    }
}
