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
};

pub fn main() anyerror!void {
    var d = Deserializer.init("true");
    const v = try getty.deserialize(null, bool, d.deserializer());

    std.debug.print("{}, {}\n", .{ v, @TypeOf(v) });
}
