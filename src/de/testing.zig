const builtin = @import("builtin");
const std = @import("std");
const expectEqual = std.testing.expectEqual;

const DeserializerInterface = @import("interfaces/deserializer.zig").Deserializer;
const err = @import("error.zig");
const free = @import("free.zig").free;
const MapAccessInterface = @import("interfaces/map_access.zig").MapAccess;
const SeqAccessInterface = @import("interfaces/seq_access.zig").SeqAccess;
const testing = @import("../testing.zig");
const Token = testing.Token;
const UnionAccessInterface = @import("interfaces/union_access.zig").UnionAccess;
const VariantAccessInterface = @import("interfaces/variant_access.zig").VariantAccess;

pub usingnamespace testing;

pub fn deserialize(
    ally: ?std.mem.Allocator,
    comptime test_case: ?[]const u8,
    comptime block: type,
    comptime Want: type,
    input: []const Token,
) !Want {
    return deserializeErr(ally, block, Want, input) catch |e| {
        if (test_case) |t| {
            return testing.logErr(t, e);
        }

        return e;
    };
}

pub fn deserializeErr(
    ally: ?std.mem.Allocator,
    comptime block: type,
    comptime Want: type,
    input: []const Token,
) !Want {
    comptime {
        std.debug.assert(@typeInfo(block) == .Struct);
        std.debug.assert(std.meta.trait.hasFunctions(block, .{ "deserialize", "Visitor" }));
    }

    var d = DefaultDeserializer.init(input);
    const deserializer = d.deserializer();

    var v = block.Visitor(Want){};
    const visitor = v.visitor();

    const got = try block.deserialize(ally, Want, deserializer, visitor);

    try std.testing.expect(d.remaining() == 0);

    return got;
}

pub fn Deserializer(comptime user_dbt: anytype, comptime deserializer_dbt: anytype) type {
    return struct {
        tokens: []const Token,

        const Self = @This();

        pub fn init(tokens: []const Token) Self {
            return .{ .tokens = tokens };
        }

        pub fn remaining(self: Self) usize {
            return self.tokens.len;
        }

        pub fn nextTokenOpt(self: *Self) ?Token {
            switch (self.remaining()) {
                0 => return null,
                else => |len| {
                    const first = self.tokens[0];
                    self.tokens = if (len == 1) &[_]Token{} else self.tokens[1..];
                    return first;
                },
            }
        }

        pub fn nextToken(self: *Self) Token {
            switch (self.remaining()) {
                0 => std.debug.panic("ran out of tokens to deserialize", .{}),
                else => |len| {
                    const first = self.tokens[0];
                    self.tokens = if (len == 1) &[_]Token{} else self.tokens[1..];
                    return first;
                },
            }
        }

        fn peekTokenOpt(self: Self) ?Token {
            return if (self.tokens.len > 0) self.tokens[0] else null;
        }

        fn peekToken(self: Self) Token {
            if (self.peekTokenOpt()) |token| {
                return token;
            } else {
                std.debug.panic("ran out of tokens to deserialize", .{});
            }
        }

        pub usingnamespace DeserializerInterface(
            *Self,
            Error,
            user_dbt,
            deserializer_dbt,
            .{
                .deserializeAny = deserializeAny,
                .deserializeBool = deserializeAny,
                .deserializeEnum = deserializeAny,
                .deserializeFloat = deserializeAny,
                .deserializeInt = deserializeAny,
                .deserializeIgnored = deserializeIgnored,
                .deserializeMap = deserializeAny,
                .deserializeOptional = deserializeAny,
                .deserializeSeq = deserializeAny,
                .deserializeString = deserializeAny,
                .deserializeStruct = deserializeAny,
                .deserializeUnion = deserializeAny,
                .deserializeVoid = deserializeAny,
            },
        );

        const Error = err.Error || error{TestExpectedEqual};

        const De = Self.@"getty.Deserializer";

        fn deserializeAny(self: *Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
            return switch (self.nextToken()) {
                .Bool => |v| try visitor.visitBool(ally, De, v),
                .I8 => |v| try visitor.visitInt(ally, De, v),
                .I16 => |v| try visitor.visitInt(ally, De, v),
                .I32 => |v| try visitor.visitInt(ally, De, v),
                .I64 => |v| try visitor.visitInt(ally, De, v),
                .I128 => |v| try visitor.visitInt(ally, De, v),
                .U8 => |v| try visitor.visitInt(ally, De, v),
                .U16 => |v| try visitor.visitInt(ally, De, v),
                .U32 => |v| try visitor.visitInt(ally, De, v),
                .U64 => |v| try visitor.visitInt(ally, De, v),
                .U128 => |v| try visitor.visitInt(ally, De, v),
                .F16 => |v| try visitor.visitFloat(ally, De, v),
                .F32 => |v| try visitor.visitFloat(ally, De, v),
                .F64 => |v| try visitor.visitFloat(ally, De, v),
                .F128 => |v| try visitor.visitFloat(ally, De, v),
                .Enum => switch (self.nextToken()) {
                    .U8 => |v| try visitor.visitInt(ally, De, v),
                    .U16 => |v| try visitor.visitInt(ally, De, v),
                    .U32 => |v| try visitor.visitInt(ally, De, v),
                    .U64 => |v| try visitor.visitInt(ally, De, v),
                    .U128 => |v| try visitor.visitInt(ally, De, v),
                    .String => |v| try visitor.visitString(ally, De, v),
                    else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
                },
                .Map => |v| blk: {
                    var m = Map{ .de = self, .len = v.len, .end = .MapEnd };
                    var value = try visitor.visitMap(ally, De, m.mapAccess());

                    try expectEqual(@as(usize, 0), m.len.?);
                    try self.assertNextToken(.MapEnd);

                    break :blk value;
                },
                .Null => try visitor.visitNull(ally, De),
                .Some => try visitor.visitSome(ally, self.deserializer()),
                .String => |v| try visitor.visitString(ally, De, v),
                .Void => try visitor.visitVoid(ally, De),
                .Seq => |v| blk: {
                    var s = Seq{ .de = self, .len = v.len, .end = .SeqEnd };
                    var value = try visitor.visitSeq(ally, De, s.seqAccess());

                    try expectEqual(@as(usize, 0), s.len.?);
                    try self.assertNextToken(.SeqEnd);

                    break :blk value;
                },
                .Struct => |v| blk: {
                    var m = Map{ .de = self, .len = v.len, .end = .StructEnd };
                    var value = try visitor.visitMap(ally, De, m.mapAccess());

                    try expectEqual(@as(usize, 0), m.len.?);
                    try self.assertNextToken(.StructEnd);

                    break :blk value;
                },
                .Union => blk: {
                    var u = Union{ .de = self };
                    break :blk try visitor.visitUnion(ally, De, u.unionAccess(), u.variantAccess());
                },

                // Panic! At The Disco
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            };
        }

        fn deserializeIgnored(self: *Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
            _ = self.nextTokenOpt();
            return try visitor.visitVoid(ally, De);
        }

        fn assertNextToken(self: *Self, expected: Token) !void {
            if (self.nextTokenOpt()) |token| {
                const token_tag = std.meta.activeTag(token);
                const expected_tag = std.meta.activeTag(expected);

                if (token_tag == expected_tag) {
                    switch (token) {
                        .MapEnd => try expectEqual(@field(token, "MapEnd"), @field(expected, "MapEnd")),
                        .SeqEnd => try expectEqual(@field(token, "SeqEnd"), @field(expected, "SeqEnd")),
                        .StructEnd => try expectEqual(@field(token, "StructEnd"), @field(expected, "StructEnd")),
                        else => |v| std.debug.panic("unexpected token: {s}", .{@tagName(v)}),
                    }
                } else {
                    @panic("expected Token::{} but deserialization wants Token::{}");
                }
            } else {
                @panic("end of tokens but deserialization wants Token::{}");
            }
        }

        const Seq = struct {
            de: *Self,
            len: ?usize,
            end: Token,

            pub usingnamespace SeqAccessInterface(
                *Seq,
                Error,
                .{ .nextElementSeed = nextElementSeed },
            );

            fn nextElementSeed(self: *Seq, ally: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
                // All elements have been deserialized.
                if (self.len.? == 0) {
                    return null;
                }

                if (self.de.peekTokenOpt()) |token| {
                    if (std.meta.eql(token, self.end)) return null;
                }

                self.len.? -= @as(usize, 1);

                return try seed.deserialize(ally, self.de.deserializer());
            }
        };

        const Map = struct {
            de: *Self,
            len: ?usize,
            end: Token,

            pub usingnamespace MapAccessInterface(
                *Map,
                Error,
                .{
                    .nextKeySeed = nextKeySeed,
                    .nextValueSeed = nextValueSeed,
                },
            );

            fn nextKeySeed(self: *Map, ally: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
                // All entries have been deserialized.
                if (self.len.? == 0) {
                    return null;
                }

                if (self.de.peekTokenOpt()) |token| {
                    if (std.meta.eql(token, self.end)) return null;
                } else {
                    return null;
                }

                self.len.? -= @as(usize, 1);

                return try seed.deserialize(ally, self.de.deserializer());
            }

            fn nextValueSeed(self: *Map, ally: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
                return try seed.deserialize(ally, self.de.deserializer());
            }
        };

        const Union = struct {
            de: *Self,

            pub usingnamespace UnionAccessInterface(
                *Union,
                Error,
                .{ .variantSeed = variantSeed },
            );

            pub usingnamespace VariantAccessInterface(
                *Union,
                Error,
                .{ .payloadSeed = payloadSeed },
            );

            fn variantSeed(self: *Union, ally: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
                if (self.de.peekTokenOpt()) |token| {
                    if (token == .String) {
                        return try seed.deserialize(ally, self.de.deserializer());
                    }
                }

                return error.InvalidType;
            }

            fn payloadSeed(self: *Union, ally: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
                if (@TypeOf(seed).Value != void) {
                    return try seed.deserialize(ally, self.de.deserializer());
                }

                if (self.de.nextToken() != .Void) {
                    return error.UnknownVariant;
                }
            }
        };
    };
}

pub const DefaultDeserializer = Deserializer(null, null);
