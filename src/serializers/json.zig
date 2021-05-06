const serialize = @import("../ser.zig").serialize;
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

        pub const Serializer = @import("../ser.zig").Serializer(
            *Self,
            Ok,
            Error,
            serialize_bool,
            serialize_int,
            serialize_float,
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

        fn serialize_bool(self: *Self, value: bool) Error!Ok {
            self.writer.writeAll(if (value) "true" else "false") catch return Error.Io;
        }

        fn serialize_int(self: *Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value)).Int.bits) {
                8, 16, 32, 64 => {
                    var buffer: [20]u8 = undefined;
                    const slice = fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
                    self.writer.writeAll(slice) catch return Error.Io;
                },
                else => @compileError("unsupported bit-width"),
            }
        }

        fn serialize_float(self: *Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value)).Int.bits) {
                32, 64 => {
                    if (math.isNan(value) or math.isInf(value)) {
                        self.writer.writeAll("null") catch return Error.io;
                    } else {
                        var buffer: [1024]u8 = undefined;
                        const slice = fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
                        self.writer.writeAll(slice) catch return Error.Io;
                    }
                },
                else => @compileError("unsupported bit-width"),
            }
        }
    };
}

pub fn toWriter(writer: anytype, value: anytype) !void {
    const Serializer = Json(@TypeOf(writer));
    var serializer = Serializer.init(writer);
    try serialize(Serializer, &serializer, value);
}

pub fn toArrayList(allocator: *mem.Allocator, value: anytype) !String {
    var array_list = String.init(allocator);
    try toWriter(array_list.writer(), value);
    return array_list;
}
