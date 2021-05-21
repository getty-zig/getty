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
            serializeSlice,
            serializeSeq,
            serializeElement,
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

        // TODO: Dow we need the bit-width check for Ints? I think JSON only
        // knows about 64-bit ints so we can just check for that.
        pub fn serializeInt(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeFloat(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        // TODO: Format escaped strings
        pub fn serializeSlice(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeSeq(self: *Self, length: usize) Error!Ok {
            //self.writer.writeByte('[') catch return Error.Io;
            //@compileError("Unused");
        }

        pub fn serializeElement(self: *Self, value: anytype) Error!Ok {
            // TODO: Make this non-ArrayList specific
            //if (!std.mem.endsWith(u8, self.writer.context.items, "[")) {
            //self.writer.writeByte(',') catch return Error.Io;
            //}

            //try ser.serialize(self, value);
            //@compileError("Unused");
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

test "Serialize - bool" {
    var t = try toString(testing_allocator, true);
    defer testing_allocator.free(t);
    var f = try toString(testing_allocator, false);
    defer testing_allocator.free(f);

    try expect(eql(u8, t, "true"));
    try expect(eql(u8, f, "false"));
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

            const max_encoded = try toString(testing_allocator, @as(T, max));
            defer testing_allocator.free(max_encoded);
            const min_encoded = try toString(testing_allocator, @as(T, min));
            defer testing_allocator.free(min_encoded);

            try expect(eql(u8, max_encoded, max_expected));
            try expect(eql(u8, min_encoded, min_expected));
        }
    }
}

test "String" {
    const value = try toString(testing_allocator, "hello");
    defer testing_allocator.free(value);

    try expect(eql(u8, value, "\"hello\""));
}

test "Array" {
    const array = [_]u32{ 'A', 'B', 'C' };
    const byte_array = [_]u8{ 'A', 'B', 'C' };

    const array_value = try toString(testing_allocator, array);
    defer testing_allocator.free(array_value);

    const string_value = try toString(testing_allocator, byte_array);
    defer testing_allocator.free(string_value);

    try expect(eql(u8, array_value, "[65,66,67]"));
    try expect(eql(u8, string_value, "\"ABC\""));
}
