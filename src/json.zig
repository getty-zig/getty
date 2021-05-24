const ser = @import("ser.zig");
const std = @import("std");

const json = std.json;
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
            /// For example, JSON containing a number is semantically incorrect
            /// when the type being deserialized into holds a String.
            Data,

            /// Prematurely reached the end of the input data.
            ///
            /// Callers that process streaming input may be interested in
            /// retrying the deserialization once more data is available.
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
            serializeString,
            serializeSequence,
            serializeStruct,
            serializeField,
        );

        writer: Writer,
        written: usize = 0,

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

        pub fn serializeInt(self: *Self, value: anytype) Error!Ok {
            var buffer: [20]u8 = undefined;
            const number = std.fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
            self.writer.writeAll(number) catch return Error.Io;
        }

        pub fn serializeFloat(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeNull(self: *Self, value: anytype) Error!Ok {
            self.writer.writeAll("null") catch return Error.Io;
        }

        pub fn serializeString(self: *Self, value: anytype) Error!Ok {
            self.writer.writeByte('"') catch return Error.Io;
            self.writer.writeAll(value) catch return Error.Io;
            self.writer.writeByte('"') catch return Error.Io;
        }

        pub fn serializeSequence(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeStruct(self: *Self) Error!fn (*Self) Error!Ok {
            self.writer.writeByte('{') catch return Error.Io;

            return struct {
                pub fn end(s: *Self) Error!Ok {
                    s.writer.writeByte('}') catch return Error.Io;
                }
            }.end;
        }

        pub fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!Ok {
            if (self.written > 0) {
                self.writer.writeByte(',') catch return Error.Io;
            }

            self.written += 1;

            ser.serialize(self, key) catch return Error.Io;
            self.writer.writeByte(':') catch return Error.Io;
            ser.serialize(self, value) catch return Error.Io;
        }
    };
}

/// Serializes a value using the JSON serializer into a provided writer.
pub fn toWriter(writer: anytype, value: anytype) !void {
    var serializer = Json(@TypeOf(writer)).init(writer);
    try ser.serialize(&serializer, value);
}

/// Returns an owned slice of a serialized JSON string.
///
/// The caller is responsible for freeing the returned memory.
pub fn toString(allocator: *mem.Allocator, value: anytype) ![]const u8 {
    var array_list = std.ArrayList(u8).init(allocator);
    errdefer array_list.deinit();

    try toWriter(array_list.writer(), value);
    return array_list.toOwnedSlice();
}

test "bool" {
    {
        var array_list = std.ArrayList(u8).init(std.testing.allocator);
        defer array_list.deinit();
        try toWriter(array_list.writer(), true);
        try std.testing.expect(std.mem.eql(u8, array_list.items, "true"));
    }

    {
        var array_list = std.ArrayList(u8).init(std.testing.allocator);
        defer array_list.deinit();
        try toWriter(array_list.writer(), false);
        try std.testing.expect(std.mem.eql(u8, array_list.items, "false"));
    }
}

test "int" {
    {
        var array_list = std.ArrayList(u8).init(std.testing.allocator);
        defer array_list.deinit();

        try toWriter(array_list.writer(), 'A');
        try std.testing.expect(std.mem.eql(u8, array_list.items, "65"));
    }

    {
        var array_list = std.ArrayList(u8).init(std.testing.allocator);
        defer array_list.deinit();

        try toWriter(array_list.writer(), std.math.maxInt(u32));
        try std.testing.expect(std.mem.eql(u8, array_list.items, "4294967295"));
    }

    {
        var array_list = std.ArrayList(u8).init(std.testing.allocator);
        defer array_list.deinit();

        try toWriter(array_list.writer(), std.math.maxInt(u64));
        try std.testing.expect(std.mem.eql(u8, array_list.items, "18446744073709551615"));
    }

    {
        var array_list = std.ArrayList(u8).init(std.testing.allocator);
        defer array_list.deinit();

        try toWriter(array_list.writer(), std.math.minInt(i32));
        try std.testing.expect(std.mem.eql(u8, array_list.items, "-2147483648"));
    }
}

test "null" {
    var array_list = std.ArrayList(u8).init(std.testing.allocator);
    defer array_list.deinit();

    try toWriter(array_list.writer(), null);
    try std.testing.expect(std.mem.eql(u8, array_list.items, "null"));
}

test "string" {
    var array_list = std.ArrayList(u8).init(std.testing.allocator);
    defer array_list.deinit();

    try toWriter(array_list.writer(), "Hello, World!");
    try std.testing.expect(std.mem.eql(u8, array_list.items, "\"Hello, World!\""));
}

test "struct" {
    var array_list = std.ArrayList(u8).init(std.testing.allocator);
    defer array_list.deinit();

    const Point = struct { x: i32, y: i32 };
    var point = Point{ .x = 1, .y = 2 };

    try toWriter(array_list.writer(), point);

    try std.testing.expectEqualSlices(u8, array_list.items, "{\"x\":1,\"y\":2}");
}

comptime {
    std.testing.refAllDecls(@This());
}
