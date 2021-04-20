const std = @import("std");

pub const Error = error{Serialize};

pub const Serialize = struct {
    serialize_fn: fn (self: *const @This(), serializer: Serializer) Error!void,

    pub fn serialize(self: *const @This(), serializer: Serializer) Error!void {
        try self.serialize_fn(self, serializer);
    }
};

pub const Serializer = struct {
    bool_fn: fn (self: *const @This(), v: bool) Error!void,
    i8_fn: fn (self: *const @This(), v: i8) Error!void,
    i16_fn: fn (self: *const @This(), v: i16) Error!void,
    i32_fn: fn (self: *const @This(), v: i32) Error!void,
    i64_fn: fn (self: *const @This(), v: i64) Error!void,
    i128_fn: fn (self: *const @This(), v: i128) Error!void,
    u8_fn: fn (self: *const @This(), v: u8) Error!void,
    u16_fn: fn (self: *const @This(), v: u16) Error!void,
    u32_fn: fn (self: *const @This(), v: u32) Error!void,
    u64_fn: fn (self: *const @This(), v: u64) Error!void,
    u128_fn: fn (self: *const @This(), v: u128) Error!void,
    f16_fn: fn (self: *const @This(), v: f16) Error!void,
    f32_fn: fn (self: *const @This(), v: f32) Error!void,
    f64_fn: fn (self: *const @This(), v: f64) Error!void,

    pub fn serialize_bool(self: *const @This(), v: bool) Error!void {
        try self.bool_fn(self, v);
    }

    pub fn serialize_i8(self: *const @This(), v: i8) Error!void {
        try self.i8_fn(self, v);
    }

    pub fn serialize_i16(self: *const @This(), v: i16) Error!void {
        try self.i16_fn(self, v);
    }

    pub fn serialize_i32(self: *const @This(), v: i32) Error!void {
        try self.i32_fn(self, v);
    }

    pub fn serialize_i64(self: *const @This(), v: i64) Error!void {
        try self.i64_fn(self, v);
    }

    pub fn serialize_i128(self: *const @This(), v: i128) Error!void {
        try self.i128_fn(self, v);
    }

    pub fn serialize_u8(self: *const @This(), v: u8) Error!void {
        try self.u8_fn(self, v);
    }

    pub fn serialize_u16(self: *const @This(), v: u16) Error!void {
        try self.u16_fn(self, v);
    }

    pub fn serialize_u32(self: *const @This(), v: u32) Error!void {
        try self.u32_fn(self, v);
    }

    pub fn serialize_u64(self: *const @This(), v: u64) Error!void {
        try self.u64_fn(self, v);
    }

    pub fn serialize_u128(self: *const @This(), v: u128) Error!void {
        try self.u128_fn(self, v);
    }

    pub fn serialize_f16(self: *const @This(), v: f16) Error!void {
        try self.f16_fn(self, v);
    }

    pub fn serialize_f32(self: *const @This(), v: f32) Error!void {
        try self.f32_fn(self, v);
    }

    pub fn serialize_f64(self: *const @This(), v: f64) Error!void {
        try self.f64_fn(self, v);
    }
};

test "Serialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    var s = TestPointr.init(std.testing.allocator);
    defer s.deinit();

    var serialize = &(@TypeOf(p).ser);
    var serializer = &(@TypeOf(s).serializer);
    try serialize.serialize(serializer.*);
    try serializer.serialize_bool(true);
}

const TestPoint = struct {
    x: i32,
    y: i32,

    const ser = Serialize{ .serialize_fn = serialize };

    fn serialize(self: *const Serialize, serializer: Serializer) Error!void {
        std.log.warn("TestPoint.serialize", .{});
    }
};

const TestPointr = struct {
    output: std.ArrayList(u8),

    fn init(allocator: *std.mem.Allocator) @This() {
        return .{ .output = std.ArrayList(u8).init(allocator) };
    }

    fn deinit(self: @This()) void {
        self.output.deinit();
    }

    const serializer = Serializer{
        .bool_fn = serialize_bool,
        .i8_fn = serialize_i8,
        .i16_fn = serialize_i16,
        .i32_fn = serialize_i32,
        .i64_fn = serialize_i64,
        .i128_fn = serialize_i128,
        .u8_fn = serialize_u8,
        .u16_fn = serialize_u16,
        .u32_fn = serialize_u32,
        .u64_fn = serialize_u64,
        .u128_fn = serialize_u128,
        .f16_fn = serialize_f16,
        .f32_fn = serialize_f32,
        .f64_fn = serialize_f64,
    };

    fn serialize_bool(self: *const Serializer, v: bool) Error!void {
        std.log.warn("TestPointr.serialize_bool", .{});
    }

    fn serialize_i8(self: *const Serializer, v: i8) Error!void {
        std.log.warn("TestPointr.serialize_i8", .{});
    }

    fn serialize_i16(self: *const Serializer, v: i16) Error!void {
        std.log.warn("TestPointr.serialize_i16", .{});
    }

    fn serialize_i32(self: *const Serializer, v: i32) Error!void {
        std.log.warn("TestPointr.serialize_i32", .{});
    }

    fn serialize_i64(self: *const Serializer, v: i64) Error!void {
        std.log.warn("TestPointr.serialize_i64", .{});
    }

    fn serialize_i128(self: *const Serializer, v: i128) Error!void {
        std.log.warn("TestPointr.serialize_i128", .{});
    }

    fn serialize_u8(self: *const Serializer, v: u8) Error!void {
        std.log.warn("TestPointr.serialize_u8", .{});
    }

    fn serialize_u16(self: *const Serializer, v: u16) Error!void {
        std.log.warn("TestPointr.serialize_u16", .{});
    }

    fn serialize_u32(self: *const Serializer, v: u32) Error!void {
        std.log.warn("TestPointr.serialize_u32", .{});
    }

    fn serialize_u64(self: *const Serializer, v: u64) Error!void {
        std.log.warn("TestPointr.serialize_u64", .{});
    }

    fn serialize_u128(self: *const Serializer, v: u128) Error!void {
        std.log.warn("TestPointr.serialize_u128", .{});
    }

    fn serialize_f16(self: *const Serializer, v: f16) Error!void {
        std.log.warn("TestPointr.serialize_f16", .{});
    }

    fn serialize_f32(self: *const Serializer, v: f32) Error!void {
        std.log.warn("TestPointr.serialize_f32", .{});
    }

    fn serialize_f64(self: *const Serializer, v: f64) Error!void {
        std.log.warn("TestPointr.serialize_f64", .{});
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
