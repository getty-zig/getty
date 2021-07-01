const ser = @import("ser.zig");
const std = @import("std");

const json = std.json;

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

        /// Implements `getty.ser.Serializer`.
        pub const Serializer = ser.Serializer(
            *Self,
            Ok,
            Error,
            serializeBool,
            serializeElement,
            serializeField,
            serializeFloat,
            serializeInt,
            serializeNull,
            serializeSequence,
            serializeString,
            serializeStruct,
            serializeVariant,
        );

        writer: Writer,
        _written: usize = 0,

        pub fn serializer(self: *Self) Serializer {
            return .{ .context = self };
        }

        pub fn init(writer: anytype) Self {
            return .{
                .writer = writer,
            };
        }

        /// Implements `boolFn` for `getty.ser.Serializer`.
        pub fn serializeBool(self: *Self, value: bool) Error!Ok {
            self.writer.writeAll(if (value) "true" else "false") catch return Error.Io;
        }

        /// Implements `elementFn` for `getty.ser.Serializer`.
        pub fn serializeElement(self: *Self, value: anytype) Error!Ok {
            if (self._written > 0) {
                self.writer.writeByte(',') catch return Error.Io;
            }

            self._written += 1;

            ser.serialize(self, value) catch return Error.Io;
        }

        /// Implements `fieldFn` for `getty.ser.Serializer`.
        pub fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!Ok {
            if (self._written > 0) {
                self.writer.writeByte(',') catch return Error.Io;
            }

            self._written += 1;

            ser.serialize(self, key) catch return Error.Io;
            self.writer.writeByte(':') catch return Error.Io;
            ser.serialize(self, value) catch return Error.Io;
        }

        /// Implements `floatFn` for `getty.ser.Serializer`.
        pub fn serializeFloat(self: *Self, value: anytype) Error!Ok {
            json.stringify(value, .{}, self.writer) catch return Error.Io;
        }

        /// Implements `intFn` for `getty.ser.Serializer`.
        pub fn serializeInt(self: *Self, value: anytype) Error!Ok {
            var buffer: [20]u8 = undefined;
            const number = std.fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
            self.writer.writeAll(number) catch return Error.Io;
        }

        /// Implements `nullFn` for `getty.ser.Serializer`.
        pub fn serializeNull(self: *Self) Error!Ok {
            self.writer.writeAll("null") catch return Error.Io;
        }

        /// Implements `sequenceFn` for `getty.ser.Serializer`.
        pub fn serializeSequence(self: *Self) Error!fn (*Self) Error!Ok {
            self.writer.writeByte('[') catch return Error.Io;

            return struct {
                pub fn end(s: *Self) Error!Ok {
                    s.writer.writeByte(']') catch return Error.Io;
                }
            }.end;
        }

        /// Implements `stringFn` for `getty.ser.Serializer`.
        pub fn serializeString(self: *Self, value: anytype) Error!Ok {
            self.writer.writeByte('"') catch return Error.Io;
            self.writer.writeAll(value) catch return Error.Io;
            self.writer.writeByte('"') catch return Error.Io;
        }

        /// Implements `structFn` for `getty.ser.Serializer`.
        pub fn serializeStruct(self: *Self) Error!fn (*Self) Error!Ok {
            self.writer.writeByte('{') catch return Error.Io;

            return struct {
                pub fn end(s: *Self) Error!Ok {
                    s.writer.writeByte('}') catch return Error.Io;
                }
            }.end;
        }

        /// Implements `variantFn` for `getty.ser.Serializer`.
        pub fn serializeVariant(self: *Self, value: anytype) Error!Ok {
            self.serializeString(@tagName(value)) catch return Error.Io;
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
pub fn toString(allocator: *std.mem.Allocator, value: anytype) ![]const u8 {
    var array_list = std.ArrayList(u8).init(allocator);
    errdefer array_list.deinit();

    try toWriter(array_list.writer(), value);
    return array_list.toOwnedSlice();
}

comptime {
    std.testing.refAllDecls(@This());
}
