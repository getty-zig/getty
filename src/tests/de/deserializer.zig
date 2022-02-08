const std = @import("std");
const getty = @import("getty");

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const Token = @import("common/token.zig").Token;

pub const Deserializer = struct {
    tokens: []const Token,

    const Self = @This();
    const impl = @"impl Deserializer";

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
        impl.deserializer.Error,
        getty.default_dt,
        getty.default_dt,
        impl.deserializer.deserializeBool,
        impl.deserializer.deserializeEnum,
        impl.deserializer.deserializeFloat,
        impl.deserializer.deserializeInt,
        impl.deserializer.deserializeMap,
        impl.deserializer.deserializeOptional,
        impl.deserializer.deserializeSeq,
        impl.deserializer.deserializeString,
        impl.deserializer.deserializeMap,
        impl.deserializer.deserializeVoid,
    );
};

const @"impl Deserializer" = struct {
    pub const deserializer = struct {
        pub const Error = getty.de.Error || error{TestExpectedEqual};

        pub fn deserializeBool(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            switch (self.nextToken()) {
                .Bool => |v| return try visitor.visitBool(allocator, Deserializer.@"getty.Deserializer", v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        pub fn deserializeEnum(
            _: *Deserializer,
            _: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {}

        pub fn deserializeFloat(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            return switch (self.nextToken()) {
                .F16 => |v| try visitor.visitFloat(allocator, Deserializer.@"getty.Deserializer", v),
                .F32 => |v| try visitor.visitFloat(allocator, Deserializer.@"getty.Deserializer", v),
                .F64 => |v| try visitor.visitFloat(allocator, Deserializer.@"getty.Deserializer", v),
                .F128 => |v| try visitor.visitFloat(allocator, Deserializer.@"getty.Deserializer", v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            };
        }

        pub fn deserializeInt(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            return switch (self.nextToken()) {
                .I8 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .I16 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .I32 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .I64 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .I128 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .U8 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .U16 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .U32 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .U64 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                .U128 => |v| try visitor.visitInt(allocator, Deserializer.@"getty.Deserializer", v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            };
        }

        pub fn deserializeMap(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            switch (self.nextToken()) {
                .Map => |v| return try visitMap(self, allocator, v.len, .MapEnd, visitor),
                .Struct => |v| return try visitMap(self, allocator, v.len, .StructEnd, visitor),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        pub fn deserializeOptional(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            switch (self.peekToken()) {
                .Null => {
                    _ = self.nextToken();
                    return try visitor.visitNull(allocator, Deserializer.@"getty.Deserializer");
                },
                .Some => {
                    _ = self.nextToken();
                    return try visitor.visitSome(allocator, Deserializer.@"getty.Deserializer");
                },
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        pub fn deserializeSeq(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            return switch (self.nextToken()) {
                .Seq => |v| try visitSeq(self, allocator, v.len, .SeqEnd, visitor),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            };
        }

        pub fn deserializeString(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            switch (self.nextToken()) {
                .String => |v| return try visitor.visitString(
                    allocator,
                    Deserializer.@"getty.Deserializer",
                    try allocator.?.dupe(u8, v),
                ),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        pub fn deserializeVoid(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            switch (self.nextToken()) {
                .Void => return try visitor.visitVoid(allocator, Deserializer.@"getty.Deserializer"),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        fn visitMap(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            len: ?usize,
            end: Token,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            var m = Map{ .de = self, .len = len, .end = end };
            var value = visitor.visitMap(allocator, Deserializer.@"getty.Deserializer", m.map());

            try assertNextToken(self, end);

            return value;
        }

        fn visitSeq(
            self: *Deserializer,
            allocator: ?std.mem.Allocator,
            len: ?usize,
            end: Token,
            visitor: anytype,
        ) Error!@TypeOf(visitor).Value {
            var s = Seq{ .de = self, .len = len, .end = end };
            var value = visitor.visitSeq(allocator, Deserializer.@"getty.Deserializer", s.seq());

            try assertNextToken(self, end);

            return value;
        }

        fn assertNextToken(self: *Deserializer, expected: Token) !void {
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
};

const Seq = struct {
    de: *Deserializer,
    len: ?usize,
    end: Token,

    const Self = @This();
    const impl = @"impl Seq";

    pub usingnamespace getty.de.Seq(
        *Self,
        impl.seq.Error,
        impl.seq.nextElementSeed,
    );
};

const @"impl Seq" = struct {
    pub const seq = struct {
        pub const Error = @"impl Deserializer".deserializer.Error;

        pub fn nextElementSeed(self: *Seq, allocator: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            if (self.de.peekTokenOpt()) |token| {
                if (std.meta.eql(token, self.end)) return null;
            }

            self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

            return try seed.deserialize(allocator, self.de.deserializer());
        }
    };
};

const Map = struct {
    de: *Deserializer,
    len: ?usize,
    end: Token,

    const Self = @This();
    const impl = @"impl Map";

    pub usingnamespace getty.de.Map(
        *Self,
        impl.map.Error,
        impl.map.nextKeySeed,
        impl.map.nextValueSeed,
    );
};

const @"impl Map" = struct {
    pub const map = struct {
        pub const Error = @"impl Deserializer".deserializer.Error;

        pub fn nextKeySeed(self: *Map, allocator: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            if (self.de.peekTokenOpt()) |token| {
                if (std.meta.eql(token, self.end)) return null;
            }

            self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

            return try seed.deserialize(allocator, self.de.deserializer());
        }

        pub fn nextValueSeed(self: *Map, allocator: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
            return try seed.deserialize(allocator, self.de.deserializer());
        }
    };
};
