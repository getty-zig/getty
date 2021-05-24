const ser = @import("ser.zig");
const std = @import("std");

const json = std.json;
const mem = std.mem;

/// A JSON serializer.
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

        pub fn serializeString(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeSequence(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        pub fn serializeStruct(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
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

comptime {
    std.testing.refAllDecls(@This());
}
