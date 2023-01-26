const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime NetAddress: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitString = visitString,
            },
        );

        const Value = NetAddress;

        fn visitString(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            const max_ipv6_chars = 47;
            const max_port_chars = 6;

            if (input.len > max_ipv6_chars + max_port_chars) {
                // Address is too long.
                return error.InvalidValue;
            }

            // Parse port number from IP address.
            var port: u16 = undefined;
            var port_len: usize = 0;
            {
                var port_str: []const u8 = "";
                switch (std.mem.count(u8, input, ":")) {
                    0 => { // Missing port number
                        return error.InvalidValue;
                    },
                    1 => { // IPv4
                        var iter = std.mem.splitBackwards(u8, input, ":");
                        if (iter.next()) |port_field| {
                            port_str = port_field;
                        } else {
                            // No port separator, meaning that IPv4 address is
                            // either incorrect or cannot be deserialized into a
                            // std.net.Address.
                            return error.InvalidValue;
                        }
                    },
                    else => { // IPv6
                        if (!std.mem.startsWith(u8, input, "[")) {
                            // IPv6 address is missing opening bracket separator.
                            return error.InvalidValue;
                        }

                        if (std.mem.count(u8, input, "]:") == 0) {
                            // IPv6 address is missing closing bracket separator.
                            return error.InvalidValue;
                        }

                        var iter = std.mem.splitBackwards(u8, input, "]:");
                        if (iter.next()) |port_field| {
                            port_str = port_field;
                        }
                    },
                }

                // Compute length of port number.
                for (port_str) |c| {
                    switch (c) {
                        '0'...'9' => port_len += 1,
                        else => return error.InvalidValue, // Port number contains non-digits.
                    }
                }

                if (port_len == 0) {
                    // Address has a colon separator but is missing a port number.
                    return error.InvalidValue;
                }

                const radix = 10;
                port = std.fmt.parseInt(u16, port_str[0..port_len], radix) catch return error.InvalidValue;
            }

            // Remove '[' and ']' characters from the IP address, if any exist.
            var addr_port_str = [_]u8{0} ** (max_ipv6_chars + max_port_chars);
            var addr_port_len: usize = 0;
            for (input) |c| {
                if (c == '[' or c == ']') {
                    continue;
                }

                addr_port_str[addr_port_len] = c;
                addr_port_len += 1;
            }

            const end = addr_port_len - port_len - 1; // The 1 is for the colon separator.
            return std.net.Address.resolveIp(addr_port_str[0..end], port) catch error.InvalidValue;
        }

        const Child = std.meta.Child(Value);
    };
}
