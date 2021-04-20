//! A data structure serializable into any data format supported by Getty.
//!
//! Getty provides `Serialize` implementations for many Zig primitive and
//! standard library types.
//!
//! Additionally, Getty provides `Serialize` implementations for structs and
//! enums that users may import into their program.

const std = @import("std");
const Serializer = @import("Serializer.zig");
const Serialize = @This();

pub const Error = error{Serialize};

serialize_fn: fn (self: *const Serialize, serializer: Serializer) Error!void,

/// Serialize this value into the given Getty serializer.
pub fn serialize(self: *const Serialize, serializer: Serializer) Error!void {
    try self.serialize_fn(self, serializer);
}

test "Serialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    var s = TestPointer.init(std.testing.allocator);
    defer s.deinit();

    var ser = &(@TypeOf(p).ser);
    var serializer = &(@TypeOf(s).serializer);
    try ser.serialize(serializer.*);
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

const TestPointer = struct {
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
        std.log.warn("TestPointer.serialize_bool", .{});
    }

    fn serialize_i8(self: *const Serializer, v: i8) Error!void {
        std.log.warn("TestPointer.serialize_i8", .{});
    }

    fn serialize_i16(self: *const Serializer, v: i16) Error!void {
        std.log.warn("TestPointer.serialize_i16", .{});
    }

    fn serialize_i32(self: *const Serializer, v: i32) Error!void {
        std.log.warn("TestPointer.serialize_i32", .{});
    }

    fn serialize_i64(self: *const Serializer, v: i64) Error!void {
        std.log.warn("TestPointer.serialize_i64", .{});
    }

    fn serialize_i128(self: *const Serializer, v: i128) Error!void {
        std.log.warn("TestPointer.serialize_i128", .{});
    }

    fn serialize_u8(self: *const Serializer, v: u8) Error!void {
        std.log.warn("TestPointer.serialize_u8", .{});
    }

    fn serialize_u16(self: *const Serializer, v: u16) Error!void {
        std.log.warn("TestPointer.serialize_u16", .{});
    }

    fn serialize_u32(self: *const Serializer, v: u32) Error!void {
        std.log.warn("TestPointer.serialize_u32", .{});
    }

    fn serialize_u64(self: *const Serializer, v: u64) Error!void {
        std.log.warn("TestPointer.serialize_u64", .{});
    }

    fn serialize_u128(self: *const Serializer, v: u128) Error!void {
        std.log.warn("TestPointer.serialize_u128", .{});
    }

    fn serialize_f16(self: *const Serializer, v: f16) Error!void {
        std.log.warn("TestPointer.serialize_f16", .{});
    }

    fn serialize_f32(self: *const Serializer, v: f32) Error!void {
        std.log.warn("TestPointer.serialize_f32", .{});
    }

    fn serialize_f64(self: *const Serializer, v: f64) Error!void {
        std.log.warn("TestPointer.serialize_f64", .{});
    }
};

comptime {
    std.testing.refAllDecls(Serialize);
}
