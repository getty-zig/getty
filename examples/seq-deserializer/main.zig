const std = @import("std");
const getty = @import("getty");

const Deserializer = struct {
    tokens: std.json.TokenStream,

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

    const Error = getty.de.Error || std.json.TokenStream.Error;

    const De = Self.@"getty.Deserializer";

    pub fn init(s: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(s) };
    }

    fn deserializeBool(self: *Self, allocator: ?std.mem.Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    fn deserializeSeq(self: *Self, allocator: ?std.mem.Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .ArrayBegin) {
                var sa = SeqAccess{ .de = self };
                return try v.visitSeq(allocator, De, sa.seqAccess());
            }
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

        fn nextElementSeed(self: *@This(), allocator: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            const element = seed.deserialize(allocator, self.de.deserializer()) catch |err| {
                // Encountered end of JSON before ']', so return an error.
                if (self.de.tokens.i - 1 >= self.de.tokens.slice.len) {
                    return err;
                }

                // If ']' is encountered, return null. Otherwise, return an error.
                return switch (self.de.tokens.slice[self.de.tokens.i - 1]) {
                    ']' => null,
                    else => err,
                };
            };

            return element;
        }
    };
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    var d = Deserializer.init("[true, false]");
    const v = try getty.deserialize(allocator, std.ArrayList(bool), d.deserializer());
    defer v.deinit();

    std.debug.print("{any}, {}\n", .{ v.items, @TypeOf(v) });
}
