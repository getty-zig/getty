const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Deserializer,
        Error,
        getty.default_dt,
        getty.default_dt,
        deserializeBool,
        deserializeEnum,
        deserializeFloat,
        deserializeInt,
        deserializeMap,
        deserializeOptional,
        deserializeSeq,
        deserializeString,
        deserializeStruct,
        deserializeVoid,
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    fn deserializeFloat(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(allocator, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeInt(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);

                if (token.Number.is_integer) {
                    return try switch (str[0]) {
                        '-' => v.visitInt(allocator, De, try std.fmt.parseInt(i64, str, 10)),
                        else => v.visitInt(allocator, De, try std.fmt.parseInt(u64, str, 10)),
                    };
                }
            }
        }

        return error.InvalidType;
    }

    fn deserializeOptional(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        const backup = self.tokens;

        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitNull(allocator, De);
            }

            self.tokens = backup;
            return try v.visitSome(allocator, self.deserializer());
        }

        return error.InvalidType;
    }

    fn deserializeVoid(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(allocator, De);
            }
        }

        return error.InvalidType;
    }

    fn deserializeString(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeEnum(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, str);
            }
        }

        return error.InvalidType;
    }

    fn deserializeMap(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        const Map = struct {
            de: *Deserializer,

            pub usingnamespace getty.de.Map(
                *@This(),
                Error,
                nextKeySeed,
                nextValueSeed,
            );

            fn nextKeySeed(map: *@This(), alloc: ?Allocator, seed: anytype) !?@TypeOf(seed).Value {
                if (try map.de.tokens.next()) |token| {
                    if (token == .ObjectEnd) {
                        return null;
                    }

                    if (token == .String) {
                        const str = token.String.slice(map.de.tokens.slice, map.de.tokens.i - 1);
                        return try alloc.?.dupe(u8, str);
                    }
                }

                return error.InvalidType;
            }

            fn nextValueSeed(map: *@This(), alloc: ?Allocator, seed: anytype) !@TypeOf(seed).Value {
                return try seed.deserialize(alloc, map.de.deserializer());
            }
        };

        if (try self.tokens.next()) |token| {
            if (token == .ObjectBegin) {
                var m = Map{ .de = self };
                const map = m.map();

                return try v.visitMap(allocator, De, map);
            }
        }

        return error.InvalidType;
    }

    fn deserializeSeq(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        const Seq = struct {
            de: *Deserializer,

            pub usingnamespace getty.de.SeqAccess(
                *@This(),
                Error,
                nextElementSeed,
            );

            fn nextElementSeed(seq: *@This(), alloc: ?Allocator, seed: anytype) !?@TypeOf(seed).Value {
                const element = seed.deserialize(alloc, seq.de.deserializer()) catch |err| {
                    if (seq.de.tokens.i - 1 >= seq.de.tokens.slice.len) {
                        return err;
                    }

                    return switch (seq.de.tokens.slice[seq.de.tokens.i - 1]) {
                        ']' => null,
                        else => err,
                    };
                };

                return element;
            }
        };

        if (try self.tokens.next()) |token| {
            if (token == .ArrayBegin) {
                var s = Seq{ .de = self };
                const seq = s.seqAccess();

                return try v.visitSeq(allocator, De, seq);
            }
        }

        return error.InvalidType;
    }

    fn deserializeStruct(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        const Map = struct {
            de: *Deserializer,

            pub usingnamespace getty.de.Map(
                *@This(),
                Error,
                nextKeySeed,
                nextValueSeed,
            );

            fn nextKeySeed(map: *@This(), _: ?Allocator, seed: anytype) !?@TypeOf(seed).Value {
                if (try map.de.tokens.next()) |token| {
                    if (token == .ObjectEnd) {
                        return null;
                    }

                    if (token == .String) {
                        return token.String.slice(map.de.tokens.slice, map.de.tokens.i - 1);
                    }
                }

                return error.InvalidType;
            }

            fn nextValueSeed(map: *@This(), alloc: ?Allocator, seed: anytype) !@TypeOf(seed).Value {
                return try seed.deserialize(alloc, map.de.deserializer());
            }
        };

        if (try self.tokens.next()) |token| {
            if (token == .ObjectBegin) {
                var m = Map{ .de = self };
                const map = m.map();

                return try v.visitMap(allocator, De, map);
            }
        }

        return error.InvalidType;
    }
};

pub fn main() anyerror!void {
    const T = struct {
        a: bool,
        b: u32,
        c: f32,
        d: []const u8,
        e: [2]enum { foo, bar },
        f: struct { x: i32, y: i32 },
    };

    const input =
        \\{
        \\ "a": true,
        \\ "b": 1,
        \\ "c": 3.14,
        \\ "d": "Getty!",
        \\ "e": ["foo","bar"],
        \\ "f": {"x":1,"y":2}
        \\}
    ;

    var d = Deserializer{ .tokens = std.json.TokenStream.init(input) };
    const deserializer = d.deserializer();

    const result = try getty.deserialize(std.heap.page_allocator, T, deserializer);
    defer getty.de.free(std.heap.page_allocator, result);

    std.debug.print("{}\n", .{result.a});
    std.debug.print("{}\n", .{result.b});
    std.debug.print("{}\n", .{result.c});
    std.debug.print("{s}\n", .{result.d});
    std.debug.print("{any}\n", .{result.e});
    std.debug.print("{}\n", .{result.f});
}
