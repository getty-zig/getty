const std = @import("std");

const Error = error{Deserialize};

const Deserialize = struct {
    deserializeFn: fn (self: *const @This(), deserializer: Deserializer) Error!void,

    fn deserialize(self: *const @This(), deserializer: Deserializer) Error!void {
        std.debug.print("Deserialize.deserialize\n", .{});
    }
};

const Deserializer = struct {
    deserializeBoolFn: fn (self: *const @This(), v: bool) void,

    fn deserializeBool(self: *const @This(), v: bool) void {
        std.debug.print("Deserializer.deserializeBool\n", .{});
    }
};

const TestPoint = struct {
    x: i32,
    y: i32,

    const de = Deserialize{ .deserializeFn = deserialize };

    fn deserialize(self: *const Deserialize, deserializer: Deserializer) Error!void {
        std.log.warn("Deserialize", .{});
    }
};

const TestDeserializer = struct {
    v: bool,

    const deserializer = Deserializer{
        .deserializeBoolFn = deserializeBool,
    };

    fn deserializeBool(self: *const Deserializer, v: bool) void {
        std.debug.print("TestDeserializer.serializeBool\n", .{});
    }
};

test "Deserialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    var d = TestDeserializer{ .v = true };

    var deserialize = &(@TypeOf(p).de);
    try deserialize.deserialize(@TypeOf(d).deserializer);
}

comptime {
    std.testing.refAllDecls(@This());
}
