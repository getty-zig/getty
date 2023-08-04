const std = @import("std");
const getty = @import("getty");

const BUF_SIZE = 1024;

fn Deserializer(comptime Reader: type) type {
    const JsonReader = std.json.Reader(BUF_SIZE, Reader);

    return struct {
        tokens: JsonReader,

        const Self = @This();

        pub usingnamespace getty.Deserializer(
            *Self,
            Error,
            null,
            null,
            .{
                .deserializeBool = deserializeBool,
            },
        );

        const Error = getty.de.Error || std.json.Error;

        const De = Self.@"getty.Deserializer";

        pub fn init(ally: std.mem.Allocator, reader: Reader) Self {
            return .{
                .tokens = JsonReader.init(ally, reader),
            };
        }

        pub fn deinit(self: *Self) void {
            self.tokens.deinit();
        }

        fn deserializeBool(self: *Self, ally: ?std.mem.Allocator, v: anytype) Error!@TypeOf(v).Value {
            const token = try self.tokens.next();
            if (token == .true or token == .false) {
                return try v.visitBool(ally, De, token == .true);
            }

            return error.InvalidType;
        }
    };
}

pub fn main() anyerror!void {
    var fbs = std.io.fixedBufferStream("true");
    const reader = fbs.reader();

    var d = Deserializer(@TypeOf(reader)).init(std.heap.page_allocator, reader);
    defer d.deinit();

    const v = try getty.deserialize(null, bool, d.deserializer());

    std.debug.print("{}, {}\n", .{ v, @TypeOf(v) });
}
