const std = @import("std");
const getty = @import("getty");

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const Token = @import("common/token.zig").Token;

pub const Deserializer = struct {
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

    pub usingnamespace getty.Deserializer(
        *Self,
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

    const Error = getty.de.Error || error{TestExpectedEqual};

    fn deserializeBool(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Bool => |v| return try visitor.visitBool(allocator, Self.@"getty.Deserializer", v),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeEnum(_: *Self, _: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {}

    fn deserializeFloat(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        return switch (self.nextToken()) {
            .F16 => |v| try visitor.visitFloat(allocator, Self.@"getty.Deserializer", v),
            .F32 => |v| try visitor.visitFloat(allocator, Self.@"getty.Deserializer", v),
            .F64 => |v| try visitor.visitFloat(allocator, Self.@"getty.Deserializer", v),
            .F128 => |v| try visitor.visitFloat(allocator, Self.@"getty.Deserializer", v),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        };
    }

    fn deserializeInt(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        return switch (self.nextToken()) {
            .I8 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .I16 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .I32 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .I64 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .I128 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U8 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U16 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U32 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U64 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U128 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        };
    }

    fn deserializeMap(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Map => |v| {
                var m = Map{ .de = self, .len = v.len, .end = .MapEnd };
                var value = visitor.visitMap(allocator, Self.@"getty.Deserializer", m.map());

                try self.assertNextToken(.MapEnd);

                return value;
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeOptional(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.peekToken()) {
            .Null => {
                _ = self.nextToken();
                return try visitor.visitNull(allocator, Self.@"getty.Deserializer");
            },
            .Some => {
                _ = self.nextToken();
                return try visitor.visitSome(allocator, Self.@"getty.Deserializer");
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeSeq(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Seq => |v| {
                var s = Seq{ .de = self, .len = v.len, .end = .SeqEnd };
                var value = visitor.visitSeq(allocator, Self.@"getty.Deserializer", s.seq());

                try self.assertNextToken(.SeqEnd);

                return value;
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeString(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .String => |v| return try visitor.visitString(
                allocator,
                Self.@"getty.Deserializer",
                try allocator.?.dupe(u8, v),
            ),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeStruct(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Struct => |v| {
                var s = Struct{ .de = self, .len = v.len, .end = .StructEnd };
                var value = visitor.visitMap(allocator, Self.@"getty.Deserializer", s.map());

                try self.assertNextToken(.StructEnd);

                return value;
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeVoid(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Void => return try visitor.visitVoid(allocator, Self.@"getty.Deserializer"),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
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
};

const Seq = struct {
    de: *Deserializer,
    len: ?usize,
    end: Token,

    const Self = @This();

    pub usingnamespace getty.de.Seq(
        *Self,
        Deserializer.Error,
        nextElementSeed,
    );

    fn nextElementSeed(self: *Seq, allocator: ?std.mem.Allocator, seed: anytype) Deserializer.Error!?@TypeOf(seed).Value {
        if (self.de.peekTokenOpt()) |token| {
            if (std.meta.eql(token, self.end)) return null;
        }

        self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

        return try seed.deserialize(allocator, self.de.deserializer());
    }
};

const Map = struct {
    de: *Deserializer,
    len: ?usize,
    end: Token,

    const Self = @This();

    pub usingnamespace getty.de.Map(
        *Self,
        Deserializer.Error,
        nextKeySeed,
        nextValueSeed,
    );

    fn nextKeySeed(self: *Map, allocator: ?std.mem.Allocator, seed: anytype) Deserializer.Error!?@TypeOf(seed).Value {
        if (self.de.peekTokenOpt()) |token| {
            if (std.meta.eql(token, self.end)) return null;
        } else {
            return null;
        }

        self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

        return try seed.deserialize(allocator, self.de.deserializer());
    }

    fn nextValueSeed(self: *Map, allocator: ?std.mem.Allocator, seed: anytype) Deserializer.Error!@TypeOf(seed).Value {
        return try seed.deserialize(allocator, self.de.deserializer());
    }
};

const Struct = struct {
    de: *Deserializer,
    len: ?usize,
    end: Token,

    const Self = @This();

    pub usingnamespace getty.de.Map(
        *Self,
        Deserializer.Error,
        nextKeySeed,
        nextValueSeed,
    );

    fn nextKeySeed(self: *Struct, _: ?std.mem.Allocator, seed: anytype) Deserializer.Error!?@TypeOf(seed).Value {
        if (self.de.peekTokenOpt()) |token| {
            if (std.meta.eql(token, self.end)) return null;
        } else {
            return null;
        }

        if (self.de.nextTokenOpt()) |token| {
            self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

            if (token != .String) {
                return error.InvalidType;
            }

            return token.String;
        } else {
            return null;
        }
    }

    fn nextValueSeed(self: *Struct, allocator: ?std.mem.Allocator, seed: anytype) Deserializer.Error!@TypeOf(seed).Value {
        return try seed.deserialize(allocator, self.de.deserializer());
    }
};
