const ser = @import("ser.zig");
const std = @import("std");

const fmt = std.fmt;
const json = std.json;
const math = std.math;
const mem = std.mem;

pub fn Json(comptime Writer: type) type {
    return struct {
        const Self = @This();

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

        pub const Serializer = ser.Serializer(
            *Self,
            Ok,
            Error,
            serializeBool,
            serializeInt,
            serializeFloat,
            serializeNull,
            serializeSlice,
        );

        writer: Writer,

        pub fn serializer(self: *Self) Serializer {
            return .{ .context = self };
        }

        pub fn init(writer: anytype) Self {
            return .{
                .writer = writer,
            };
        }

        pub fn serializeBool(self: *Self, value: bool) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeInt(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeFloat(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeNull(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeSlice(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }
    };
}

pub fn toWriter(writer: anytype, value: anytype) !void {
    var serializer = Json(@TypeOf(writer)).init(writer);
    try ser.serialize(&serializer, value);
}

pub fn toString(allocator: *mem.Allocator, value: anytype) ![]const u8 {
    var array_list = std.ArrayList(u8).init(allocator);
    errdefer array_list.deinit();
    try toWriter(array_list.writer(), value);
    return array_list.toOwnedSlice();
}

const eql = std.mem.eql;
const expect = std.testing.expect;
const testing_allocator = std.testing.allocator;

test "Serialize - null" {
    var result = try toString(testing_allocator, null);
    defer testing_allocator.free(result);

    try expect(eql(u8, result, "null"));
}

test "Serialize - bool" {
    var true_result = try toString(testing_allocator, true);
    defer testing_allocator.free(true_result);
    var false_result = try toString(testing_allocator, false);
    defer testing_allocator.free(false_result);

    try expect(eql(u8, true_result, "true"));
    try expect(eql(u8, false_result, "false"));
}

test "Serialize - integer" {
    comptime var bits = 0;

    inline while (bits < 64) : (bits += 1) {
        const Signed = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = bits } });
        const Unsigned = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = bits } });

        inline for (&[_]type{ Signed, Unsigned }) |T| {
            const max = std.math.maxInt(T);
            const min = std.math.minInt(T);

            var max_buf: [20]u8 = undefined;
            var min_buf: [20]u8 = undefined;
            const max_expected = std.fmt.bufPrint(&max_buf, "{}", .{max}) catch unreachable;
            const min_expected = std.fmt.bufPrint(&min_buf, "{}", .{min}) catch unreachable;

            const max_result = try toString(testing_allocator, @as(T, max));
            defer testing_allocator.free(max_result);
            const min_result = try toString(testing_allocator, @as(T, min));
            defer testing_allocator.free(min_result);

            try expect(eql(u8, max_result, max_expected));
            try expect(eql(u8, min_result, min_expected));
        }
    }
}

test "Serialize - string" {
    const result = try toString(testing_allocator, "hello");
    defer testing_allocator.free(result);

    try expect(eql(u8, result, "\"hello\""));
}

test "Serialize - array" {
    const array = [_]u32{ 'A', 'B', 'C' };
    const byte_array = [_]u8{ 'A', 'B', 'C' };

    const array_result = try toString(testing_allocator, array);
    defer testing_allocator.free(array_result);

    const string_result = try toString(testing_allocator, byte_array);
    defer testing_allocator.free(string_result);

    try expect(eql(u8, array_result, "[65,66,67]"));
    try expect(eql(u8, string_result, "\"ABC\""));
}

test "Serialize - optional" {
    const some: ?i8 = 1;
    const none: ?i8 = null;

    const some_result = try toString(testing_allocator, some);
    defer testing_allocator.free(some_result);
    const none_result = try toString(testing_allocator, none);
    defer testing_allocator.free(none_result);

    try expect(eql(u8, some_result, "1"));
    try expect(eql(u8, none_result, "null"));
}

test "Serialize - error set" {
    const result = try toString(testing_allocator, error{Error}.Error);
    defer testing_allocator.free(result);

    try expect(eql(u8, result, "\"Error\""));
}

test "Serialize - vector" {
    const result = try toString(testing_allocator, @splat(2, @as(u32, 1)));
    defer testing_allocator.free(result);

    try expect(eql(u8, result, "[1,1]"));
}

test "Serialize - tagged union" {
    const Union = union(enum) { int: i32, boolean: bool };
    var int_union = Union{ .int = 42 };
    var bool_union = Union{ .boolean = true };

    const int_result = try toString(testing_allocator, int_union);
    defer testing_allocator.free(int_result);
    const bool_result = try toString(testing_allocator, bool_union);
    defer testing_allocator.free(bool_result);

    try expect(eql(u8, int_result, "42"));
    try expect(eql(u8, bool_result, "true"));
}
