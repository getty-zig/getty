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
                .deserializeSeq = deserializeSeq,
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

        fn deserializeSeq(self: *Self, ally: ?std.mem.Allocator, v: anytype) Error!@TypeOf(v).Value {
            const token = try self.tokens.next();
            if (token == .array_begin) {
                var sa = SeqAccess{ .de = self };
                return try v.visitSeq(ally, De, sa.seqAccess());
            }

            return error.InvalidType;
        }

        const SeqAccess = struct {
            de: *Self,

            pub usingnamespace getty.de.SeqAccess(
                *@This(),
                Self.Error,
                .{
                    .nextElementSeed = nextElementSeed,
                },
            );

            fn nextElementSeed(self: *@This(), ally: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
                // If ']' is encountered, return null
                if (try self.de.tokens.peekNextTokenType() == .array_end) {
                    return null;
                }

                const element = try seed.deserialize(ally, self.de.deserializer());

                return element;
            }
        };
    };
}

pub fn main() anyerror!void {
    const page_ally = std.heap.page_allocator;

    var fbs = std.io.fixedBufferStream("[true, false]");
    const reader = fbs.reader();

    var d = Deserializer(@TypeOf(reader)).init(page_ally, reader);
    defer d.deinit();

    const v = try getty.deserialize(page_ally, std.ArrayList(bool), d.deserializer());
    defer v.deinit();

    std.debug.print("{any}, {}\n", .{ v.items, @TypeOf(v) });
}
