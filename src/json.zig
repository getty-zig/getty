const ser = @import("ser.zig");
const std = @import("std");

const json = std.json;

pub fn Json(comptime Writer: type) type {
    return struct {
        writer: Writer,
        _written: usize = 0,

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

        //pub const Map = SM;
        pub const Sequence = SI;
        pub const Struct = SS;
        //pub const Tuple = ST;

        /// Implements `getty.ser.Serializer`.
        pub const Serializer = ser.Serializer(
            *Self,
            Ok,
            Error,
            //Map,
            Sequence,
            Struct,
            //Tuple,
            serializeBool,
            serializeFloat,
            serializeInt,
            serializeNull,
            serializeSequence,
            serializeString,
            serializeStruct,
            serializeVariant,
        );

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
        pub fn serializeSequence(self: *Self) Error!Sequence {
            self.writer.writeByte('[') catch return Error.Io;

            return self.getSequence();
        }

        /// Implements `stringFn` for `getty.ser.Serializer`.
        pub fn serializeString(self: *Self, value: anytype) Error!Ok {
            self.writer.writeByte('"') catch return Error.Io;
            self.writer.writeAll(value) catch return Error.Io;
            self.writer.writeByte('"') catch return Error.Io;
        }

        /// Implements `structFn` for `getty.ser.Serializer`.
        pub fn serializeStruct(self: *Self) Error!Struct {
            self.writer.writeByte('{') catch return Error.Io;

            return self.getStruct();
        }

        /// Implements `variantFn` for `getty.ser.Serializer`.
        pub fn serializeVariant(self: *Self, value: anytype) Error!Ok {
            self.serializeString(@tagName(value)) catch return Error.Io;
        }

        /// Implements `getty.ser.SerializeSequence`.
        pub const SI = ser.SerializeSequence(
            *Self,
            Ok,
            Error,
            serializeElement,
            seqEnd,
        );

        pub fn getSequence(self: *Self) SI {
            return .{ .context = self };
        }

        /// Implements `elementFn` for `getty.ser.SerializeSequence`.
        ///
        /// FIXME: Pretty sure the _written usage is wrong for elements and
        /// fields.
        pub fn serializeElement(self: *Self, value: anytype) Error!void {
            if (self._written > 0) {
                self.writer.writeByte(',') catch return Error.Io;
            }

            self._written += 1;

            ser.serialize(self, value) catch return Error.Io;
        }

        /// Implements `endFn` for `getty.ser.SerializeSequence`.
        pub fn seqEnd(self: *Self) Error!Ok {
            self.writer.writeByte(']') catch return Error.Io;
        }

        /// Implements `getty.ser.SerializeStruct`.
        pub const SS = ser.SerializeStruct(
            *Self,
            Ok,
            Error,
            serializeField,
            structEnd,
        );

        pub fn getStruct(self: *Self) SS {
            return .{ .context = self };
        }

        /// Implements `fieldFn` for `getty.ser.SerializeStruct`.
        pub fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!void {
            if (self._written > 0) {
                self.writer.writeByte(',') catch return Error.Io;
            }

            self._written += 1;

            ser.serialize(self, key) catch return Error.Io;
            self.writer.writeByte(':') catch return Error.Io;
            ser.serialize(self, value) catch return Error.Io;
        }

        /// Implements `endFn` for `getty.ser.SerializeStruct`.
        pub fn structEnd(self: *Self) Error!Ok {
            self.writer.writeByte('}') catch return Error.Io;
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
