const std = @import("std");
const t = @import("../testing.zig");

const NetAddressVisitor = @import("../impls/visitor/net_address.zig").Visitor;

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
    allocator: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeString(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return NetAddressVisitor(T);
}

test "deserialize - std.net.Address" {
    const builtin = @import("builtin");

    // TODO: https://github.com/getty-zig/getty/issues/90
    if (builtin.os.tag != .windows) {
        const ipv4 = "127.0.0.1";
        const ipv6 = "2001:0db8:85a3:0000:0000:8a2e:0370";
        const ipv6_wrapped = "[" ++ ipv6 ++ "]";

        // IPv4
        {
            var addr = try std.net.Address.resolveIp(ipv4, 0);
            try t.run(deserialize, Visitor, &.{.{ .String = ipv4 ++ ":0" }}, addr);
        }

        // IPv6
        {
            var addr = try std.net.Address.resolveIp(ipv6, 80);
            try t.run(deserialize, Visitor, &.{.{ .String = ipv6_wrapped ++ ":80" }}, addr);
        }
    }
}
