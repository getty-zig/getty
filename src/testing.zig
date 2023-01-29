const std = @import("std");

pub const Token = union(enum) {
    Bool: bool,

    ComptimeInt,
    ComptimeFloat,

    I8: i8,
    I16: i16,
    I32: i32,
    I64: i64,
    I128: i128,

    U8: u8,
    U16: u16,
    U32: u32,
    U64: u64,
    U128: u128,

    F16: f16,
    F32: f32,
    F64: f64,
    F128: f128,

    String: []const u8,

    Null,
    Some,

    Void,

    Seq: struct { len: ?usize },
    SeqEnd,

    Map: struct { len: ?usize },
    MapEnd,

    Struct: struct { name: []const u8, len: usize },
    StructEnd,

    Enum,
    Union,
};

pub fn expect(comptime name: []const u8, ok: bool) !void {
    return std.testing.expect(ok) catch |e| logErr(name, e);
}

pub fn expectError(comptime name: []const u8, expected: anyerror, actual: anytype) !void {
    return std.testing.expectError(expected, actual) catch |e| logErr(name, e);
}

pub fn expectEqual(comptime name: []const u8, expected: anytype, actual: @TypeOf(expected)) !void {
    return std.testing.expectEqual(expected, actual) catch |e| logErr(name, e);
}

pub fn expectEqualSlices(comptime name: []const u8, comptime T: type, expected: []const T, actual: []const T) !void {
    return std.testing.expectEqualSlices(T, expected, actual) catch |e| logErr(name, e);
}

pub fn expectEqualStrings(comptime name: []const u8, expected: []const u8, actual: []const u8) !void {
    return std.testing.expectEqualStrings(expected, actual) catch |e| logErr(name, e);
}

pub fn logErr(comptime name: []const u8, err: anyerror) anyerror {
    std.log.err("test case \"{s}\" failed", .{name});
    return err;
}
