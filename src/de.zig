const std = @import("std");

pub const Error = error{Deserialize};

pub const Deserialize = struct {
    deserialize_fn: fn (self: *const @This(), deserializer: Deserializer) Error!void,

    fn deserialize(self: *const @This(), deserializer: Deserializer) Error!void {
        std.debug.print("Deserialize.deserialize\n", .{});
    }
};

pub const Deserializer = struct {
    bool_fn: fn (self: *const @This(), v: bool) void,

    fn deserialize_bool(self: *const @This(), v: bool) void {
        std.debug.print("Deserializer.deserialize_bool\n", .{});
    }
};

test "Deserialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    var d = TestPointr{ .v = true };

    var deserialize = &(@TypeOf(p).de);
    var deserializer = &(@TypeOf(d).deserializer);
    try deserialize.deserialize(deserializer.*);
}

const TestPoint = struct {
    x: i32,
    y: i32,

    const de = Deserialize{ .deserialize_fn = deserialize };

    fn deserialize(self: *const Deserialize, deserializer: Deserializer) Error!void {
        std.log.warn("Deserialize", .{});
    }
};

const TestPointr = struct {
    v: bool,

    const deserializer = Deserializer{
        .bool_fn = deserialize_bool,
    };

    fn deserialize_bool(self: *const Deserializer, v: bool) void {
        std.debug.print("TestPointr.serializeBool\n", .{});
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
