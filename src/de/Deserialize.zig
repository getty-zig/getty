//! A data structure deserializable from any data format supported by Getty.
//!
//! Getty provides `Deserialize` implementations for many Zig primitive and
//! standard library types.
//!
//! Additionally, Getty provides `Deserialize` implementations for structs and
//! enums that users may import into their program.

const std = @import("std");
const Deserializer = @import("Deserializer.zig");
const Deserialize = @This();

pub const Error = error{Deserialize};

deserialize_fn: fn (self: *const Deserialize, deserializer: Deserializer) Error!void,

/// Deserialize this value from the given Getty deserializer.
fn deserialize(self: *const Deserialize, deserializer: Deserializer) Error!void {
    std.debug.print("Deserialize.deserialize\n", .{});
}

test "Deserialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    var d = TestPointer{ .v = true };

    var de = &(@TypeOf(p).de);
    var deserializer = &(@TypeOf(d).deserializer);
    try de.deserialize(deserializer.*);
}

const TestPoint = struct {
    x: i32,
    y: i32,

    const de = Deserialize{ .deserialize_fn = deserialize };

    fn deserialize(self: *const Deserialize, deserializer: Deserializer) Error!void {
        std.log.warn("Deserialize", .{});
    }
};

const TestPointer = struct {
    v: bool,

    const deserializer = Deserializer{
        .bool_fn = deserialize_bool,
    };

    fn deserialize_bool(self: *const Deserializer, v: bool) void {
        std.debug.print("TestPointer.serializeBool\n", .{});
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
