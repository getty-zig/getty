const ser = @import("ser.zig");
const std = @import("std");

const fmt = std.fmt;
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
            serializeChar,
            serializeInt,
            serializeFloat,
            serializeStr,
            serializeBytes,
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
            self.writer.writeAll(if (value) "true" else "false") catch return Error.Io;
        }

        pub fn serializeChar(self: *Self, comptime value: comptime_int) Error!Ok {
            var buffer: [std.unicode.utf8CodepointSequenceLength(value) catch unreachable]u8 = undefined;
            const written = std.unicode.utf8Encode(value, &buffer) catch unreachable; // guaranteed to be encodable thanks to ser.serialize
            return self.serializeStr(&buffer);
        }

        // TODO: Dow we need the bit-width check for Ints? I think JSON only
        // knows about 64-bit ints so we can just check for that.
        pub fn serializeInt(self: *Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value))) {
                .ComptimeInt => {
                    const max = std.math.maxInt(u64);
                    const min = std.math.minInt(i64);
                    std.debug.assert(value >= min and value <= max);
                },
                .Int => |info| switch (info.bits) {
                    8, 16, 32, 64 => {},
                    else => @compileError("unsupported bit-width"),
                },
                else => unreachable,
            }

            var buffer: [20]u8 = undefined;
            const slice = fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
            self.writer.writeAll(slice) catch return Error.Io;
        }

        pub fn serializeFloat(self: *Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value)).Float.bits) {
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
        pub fn serializeStr(self: *Self, value: anytype) Error!Ok {
            self.writer.writeByte('"') catch return Error.Io;
            self.writer.writeAll(value) catch return Error.Io;
            self.writer.writeByte('"') catch return Error.Io;
        }

        pub fn serializeBytes(self: *Self, value: anytype) Error!Ok {
            try self.serializeSeq(value.len);

            for (&value) |byte| {
                try self.serializeElement(byte);
            }

            self.writer.writeByte(']') catch return Error.Io;
        }

        pub fn serializeSeq(self: *Self, length: usize) Error!Ok {
            self.writer.writeByte('[') catch return Error.Io;
        }

        pub fn serializeElement(self: *Self, value: anytype) Error!Ok {
            // TODO: Make this non-ArrayList specific
            if (!std.mem.endsWith(u8, self.writer.context.items, "[")) {
                self.writer.writeByte(',') catch return Error.Io;
            }

            try ser.serialize(self, value);
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

test "String" {
    const value = try toString(testing_allocator, "hello");
    defer testing_allocator.free(value);

    try expect(eql(u8, value, "\"hello\""));
}

test "Byte array" {
    //const array = [_]u8{};
    const array = [_]u8{1};
    //const array = [_]u8{ 1, 2, 3 };
    const value = try toString(testing_allocator, array);
    defer testing_allocator.free(value);

    //try expect(eql(u8, value, "[]"));
    try expect(eql(u8, value, "[1]"));
    //try expect(eql(u8, value, "[1,2,3]"));
}
