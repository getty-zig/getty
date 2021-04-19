const std = @import("std");

const Error = error{Serialize};

const Serialize = struct {
    serializeFn: fn (self: *const @This(), serializer: Serializer) Error!void,

    fn serialize(self: *const @This(), serializer: Serializer) Error!void {
        std.debug.print("Serialize.serialize\n", .{});
    }
};

const Serializer = struct {
    serializeBoolFn: fn (self: *const @This(), v: bool) void,

    fn serializeBool(self: *const @This(), v: bool) void {
        std.debug.print("Serializer.serializeBool\n", .{});
    }
};

const TestPoint = struct {
    x: i32,
    y: i32,

    const ser = Serialize{ .serializeFn = serialize };

    fn serialize(self: *const Serialize, serializer: Serializer) Error!void {
        std.debug.print("TestPoint.serialize\n", .{});
    }
};

const TestSerializer = struct {
    output: std.ArrayList(u8),

    fn init(allocator: *std.mem.Allocator) @This() {
        return .{ .output = std.ArrayList(u8).init(allocator) };
    }

    fn deinit(self: @This()) void {
        self.output.deinit();
    }

    const serializer = Serializer{
        .serializeBoolFn = serializeBool,
    };

    fn serializeBool(self: *const Serializer, v: bool) void {
        std.debug.print("TestSerializer.serializeBool\n", .{});
    }
};

test "Serialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    var s = TestSerializer.init(std.testing.allocator);
    defer s.deinit();

    var serialize = &(@TypeOf(p).ser);
    try serialize.serialize(@TypeOf(s).serializer);
}

comptime {
    std.testing.refAllDecls(@This());
}
