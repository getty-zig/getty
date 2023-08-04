const builtin = @import("builtin");
const std = @import("std");

const t = @import("../testing.zig");

// The maximum number of characters in an IPv6 address.
//
// Normally, IPv6 addresses can have up to 35 characters (8 groups of 4 hex
// digits separated by colons). However, there is a caveat for IPv4-mapped IPv6
// addresses, which can be up to 45 characters long. Furthermore, the format()
// function in std.net.Ip6Address encloses IPv6 addresses in brackets, making
// the maximum length of character for an IPv6 address 45 + 2 = 47 characters.
//
// In practice, std.net.Address doesn't actually seem to support IPv4-mapped
// IPv6 addresses. But, we'll account for them anyways just in case it changes.
const max_ipv6_chars = 47;

// The maximum number of characters in a port number (plus one for a colon).
//
// The largest port number is 65535.
const max_port_chars = 6;

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return T == std.net.Address;
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
    _ = ally;

    var arr = [_]u8{0} ** (max_ipv6_chars + max_port_chars);

    // UNREACHABLE: With the size values used in the array's declaration, there
    // should always be enough space for an IPv4 or IPv6 address.
    var buf = std.fmt.bufPrint(&arr, "{}", .{value}) catch unreachable;

    return try serializer.serializeString(buf);
}

test "serialize - std.net.Address" {
    // TODO: https://github.com/getty-zig/getty/issues/90
    if (builtin.os.tag != .windows) {
        // IPv4
        {
            var addr = std.net.Address.resolveIp("127.0.0.1", 80) catch return error.UnexpectedTestError;
            try t.run(null, serialize, addr, &.{.{ .String = "127.0.0.1:80" }});
        }

        // IPv6
        {
            var addr = std.net.Address.resolveIp("2001:db8:3333:4444:5555:6666:7777:8888", 80) catch return error.UnexpectedTestError;
            try t.run(null, serialize, addr, &.{.{ .String = "[2001:db8:3333:4444:5555:6666:7777:8888]:80" }});
        }

        // IPv6 (shortened)
        {
            var addr = std.net.Address.resolveIp("2001:db8:3333::7777:8888", 80) catch return error.UnexpectedTestError;
            try t.run(null, serialize, addr, &.{.{ .String = "[2001:db8:3333::7777:8888]:80" }});
        }
    }
}
