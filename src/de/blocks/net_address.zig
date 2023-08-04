const std = @import("std");

const NetAddressVisitor = @import("../impls/visitor/net_address.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == std.net.Address;
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
    return NetAddressVisitor(T);
}

test "deserialize - std.net.Address" {
    const Want = std.net.Address;

    const ipv4 = "127.0.0.1";
    const ipv6 = "2001:0db8:85a3:0000:0000:8a2e:0370";
    const ipv6_wrapped = "[" ++ ipv6 ++ "]";

    // TODO: https://github.com/getty-zig/getty/issues/90
    if (@import("builtin").os.tag != .windows) {
        const tests = .{
            .{
                .name = "IPv4 (any port)",
                .tokens = &.{.{ .String = ipv4 ++ ":0" }},
                .want = std.net.Address.resolveIp(ipv4, 0) catch return error.UnexpectedTestError,
            },
            .{
                .name = "IPv4 (specific port)",
                .tokens = &.{.{ .String = ipv4 ++ ":80" }},
                .want = std.net.Address.resolveIp(ipv4, 80) catch return error.UnexpectedTestError,
            },
            .{
                .name = "IPv6 (any port)",
                .tokens = &.{.{ .String = ipv6_wrapped ++ ":0" }},
                .want = std.net.Address.resolveIp(ipv6, 0) catch return error.UnexpectedTestError,
            },
            .{
                .name = "IPv6 (specific port)",
                .tokens = &.{.{ .String = ipv6_wrapped ++ ":80" }},
                .want = std.net.Address.resolveIp(ipv6, 80) catch return error.UnexpectedTestError,
            },
        };

        inline for (tests) |t| {
            const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);
            try testing.expect(t.name, std.net.Address.eql(t.want, got));
        }
    }
}
