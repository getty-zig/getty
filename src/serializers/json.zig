const std = @import("std");

const serialize = @import("../ser.zig").serialize;

pub const Json = @This();

pub const Ok = void;
pub const Error = error{
    /// Failure to read or write bytes on an IO stream.
    Io,

    /// Input was not syntactically valid JSON.
    Syntax,

    /// Input data was semantically incorrect.
    ///
    /// For example, JSON containing a number is semantically incorrect when the
    /// type being deserialized into holds a String.
    Data,

    /// Prematurely reached the end of the input data.
    ///
    /// Callers that process streaming input may be interested in retrying the
    /// deserialization once more data is available.
    Eof,
};

pub const Serializer = @import("../ser.zig").Serializer(
    *Json,
    Ok,
    Error,
    serialize_bool,
    serialize_i8,
    serialize_i16,
    serialize_i32,
    serialize_i64,
    serialize_i128,
    serialize_u8,
    serialize_u16,
    serialize_u32,
    serialize_u64,
    serialize_u128,
    serialize_f16,
    serialize_f32,
    serialize_f64,
);

output: std.ArrayList(u8),

pub fn init(allocator: *std.mem.Allocator) Json {
    return .{
        .output = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *Json) void {
    self.output.deinit();
}

pub fn serializer(self: *Json) Serializer {
    return .{ .context = self };
}

pub fn toArrayList(allocator: *std.mem.Allocator, v: anytype) Error!std.ArrayList(u8) {
    var json_serializer = Json.init(allocator);
    errdefer json_serializer.deinit();

    try serialize(Json, &json_serializer, v);
    return json_serializer.output;
}

fn serialize_bool(self: *Json, v: bool) Error!Ok {
    self.output.appendSlice(if (v) "true" else "false") catch return Error.Io;
}

fn serialize_i8(self: *Json, v: i8) Error!Ok {
    try self.serialize_i64(v);
}

fn serialize_i16(self: *Json, v: i16) Error!Ok {
    try self.serialize_i64(v);
}

fn serialize_i32(self: *Json, v: i32) Error!Ok {
    try self.serialize_i64(v);
}

fn serialize_i64(self: *Json, v: i64) Error!Ok {
    // UNREACHABLE: The buffer always has enough space.
    var buffer: [20]u8 = undefined;
    const slice = std.fmt.bufPrint(&buffer, "{d}", .{v}) catch unreachable;
    self.output.appendSlice(slice) catch return Error.Io;
}

fn serialize_i128(self: *Json, v: i128) Error!Ok {
    std.log.warn("TestSerializer.serialize_i128", .{});
}

fn serialize_u8(self: *Json, v: u8) Error!Ok {
    try self.serialize_u64(v);
}

fn serialize_u16(self: *Json, v: u16) Error!Ok {
    try self.serialize_u64(v);
}

fn serialize_u32(self: *Json, v: u32) Error!Ok {
    try self.serialize_u64(v);
}

fn serialize_u64(self: *Json, v: u64) Error!Ok {
    // UNREACHABLE: The buffer always has enough space.
    var buffer: [20]u8 = undefined;
    const slice = std.fmt.bufPrint(&buffer, "{d}", .{v}) catch unreachable;
    self.output.appendSlice(slice) catch return Error.Io;
}

fn serialize_u128(self: *Json, v: u128) Error!Ok {
    std.log.warn("TestSerializer.serialize_u128", .{});
}

fn serialize_f16(self: *Json, v: f16) Error!Ok {
    std.log.warn("TestSerializer.serialize_f16", .{});
}

fn serialize_f32(self: *Json, v: f32) Error!Ok {
    std.log.warn("TestSerializer.serialize_f32", .{});
}

fn serialize_f64(self: *Json, v: f64) Error!Ok {
    std.log.warn("TestSerializer.serialize_f64", .{});
}
