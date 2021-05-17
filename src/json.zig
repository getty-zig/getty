const ser = @import("ser.zig");
const std = @import("std");

const fmt = std.fmt;
const math = std.math;
const mem = std.mem;

const String = std.ArrayList(u8);

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
            serialize_bool,
            serialize_int,
            serialize_float,
            serialize_str,
            serialize_bytes,
            serialize_sequence,
            serialize_element,
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

        pub fn serialize_bool(self: *Self, value: bool) Error!Ok {
            self.writer.writeAll(if (value) "true" else "false") catch return Error.Io;
        }

        pub fn serialize_int(self: *Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value)).Int.bits) {
                8, 16, 32, 64 => {
                    var buffer: [20]u8 = undefined;
                    const slice = fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
                    self.writer.writeAll(slice) catch return Error.Io;
                },
                else => @compileError("unsupported bit-width"),
            }
        }

        pub fn serialize_float(self: *Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value)).Int.bits) {
                32, 64 => {
                    if (math.isNan(value) or math.isInf(value)) {
                        self.writer.writeAll("null") catch return Error.Io;
                    } else {
                        var buffer: [1024]u8 = undefined;
                        const slice = fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
                        self.writer.writeAll(slice) catch return Error.Io;
                    }
                },
                else => @compileError("unsupported bit-width"),
            }
        }

        // TODO: Format escaped strings
        pub fn serialize_str(self: *Self, value: anytype) Error!Ok {
            self.writer.writeByte('"') catch return Error.Io;
            self.writer.writeAll(value) catch return Error.Io;
            self.writer.writeByte('"') catch return Error.Io;
        }

        pub fn serialize_bytes(self: *Self, value: anytype) Error!Ok {
            try self.serialize_sequence(value.len);

            for (&value) |byte| {
                try self.serialize_element(byte);
            }

            self.writer.writeByte(']') catch return Error.Io;
        }

        pub fn serialize_sequence(self: *Self, length: usize) Error!Ok {
            self.writer.writeByte('[') catch return Error.Io;
        }

        pub fn serialize_element(self: *Self, value: anytype) Error!Ok {
            // TODO: Make this non-ArrayList specific
            if (!std.mem.endsWith(u8, self.writer.context.items, "[")) {
                self.writer.writeByte(',') catch return Error.Io;
            }

            try ser.serialize(self, value);
        }
    };
}

pub fn toWriter(writer: anytype, value: anytype) !void {
    const Serializer = Json(@TypeOf(writer));
    var serializer = Serializer.init(writer);
    try ser.serialize(&serializer, value);
}

pub fn toArrayList(allocator: *mem.Allocator, value: anytype) !String {
    var array_list = String.init(allocator);
    try toWriter(array_list.writer(), value);
    return array_list;
}

const eql = std.mem.eql;
const expect = std.testing.expect;
const testing_allocator = std.testing.allocator;

test "String" {
    const value = try toArrayList(testing_allocator, "hello");
    defer value.deinit();

    try expect(eql(u8, value.items, "\"hello\""));
}

test "Byte array" {
    //const array = [_]u8{};
    const array = [_]u8{1};
    //const array = [_]u8{ 1, 2, 3 };
    const value = try toArrayList(testing_allocator, array);
    defer value.deinit();

    //try expect(eql(u8, value.items, "[]"));
    try expect(eql(u8, value.items, "[1]"));
    //try expect(eql(u8, value.items, "[1,2,3]"));
}
