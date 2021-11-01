const std = @import("std");
const getty = @import("getty");

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const Token = @import("common/token.zig").Token;

pub const Deserializer = struct {
    allocator: *std.mem.Allocator,
    tokens: []const Token,

    const Self = @This();
    const impl = @"impl Deserializer";

    pub fn init(allocator: *std.mem.Allocator, tokens: []const Token) Self {
        return .{
            .allocator = allocator,
            .tokens = tokens,
        };
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
        impl.deserializer.deserializeBool,
        impl.deserializer.deserializeEnum,
        impl.deserializer.deserializeFloat,
        impl.deserializer.deserializeInt,
        impl.deserializer.deserializeMap,
        impl.deserializer.deserializeOptional,
        impl.deserializer.deserializeSequence,
        impl.deserializer.deserializeString,
        impl.deserializer.deserializeStruct,
        impl.deserializer.deserializeVoid,
    );
};

const @"impl Deserializer" = struct {
    pub const deserializer = struct {
        pub const Error = getty.de.Error || error{TestExpectedEqual};

        pub fn deserializeBool(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            switch (self.nextToken()) {
                .Bool => |v| return try visitor.visitBool(Error, v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        pub fn deserializeEnum(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            _ = self;
        }

        pub fn deserializeFloat(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            return switch (self.nextToken()) {
                .F16 => |v| try visitor.visitFloat(Error, v),
                .F32 => |v| try visitor.visitFloat(Error, v),
                .F64 => |v| try visitor.visitFloat(Error, v),
                .F128 => |v| try visitor.visitFloat(Error, v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            };
        }

        pub fn deserializeInt(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            return switch (self.nextToken()) {
                .I8 => |v| try visitor.visitInt(Error, v),
                .I16 => |v| try visitor.visitInt(Error, v),
                .I32 => |v| try visitor.visitInt(Error, v),
                .I64 => |v| try visitor.visitInt(Error, v),
                .I128 => |v| try visitor.visitInt(Error, v),
                .U8 => |v| try visitor.visitInt(Error, v),
                .U16 => |v| try visitor.visitInt(Error, v),
                .U32 => |v| try visitor.visitInt(Error, v),
                .U64 => |v| try visitor.visitInt(Error, v),
                .U128 => |v| try visitor.visitInt(Error, v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            };
        }

        pub fn deserializeOptional(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            switch (self.peekToken()) {
                .Null => {
                    _ = self.nextToken();
                    return try visitor.visitNull(Error);
                },
                .Some => {
                    _ = self.nextToken();
                    return try visitor.visitSome(Error);
                },
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        pub fn deserializeSequence(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            return switch (self.nextToken()) {
                .Seq => |v| try visit_seq(self, v.len, .SeqEnd, visitor),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            };
        }

        pub fn deserializeString(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            switch (self.nextToken()) {
                .String => |v| return try visitor.visitString(Error, v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        pub fn deserializeMap(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            _ = self;
        }

        pub fn deserializeStruct(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            _ = self;
        }

        pub fn deserializeVoid(self: *Deserializer, visitor: anytype) Error!@TypeOf(visitor).Value {
            switch (self.nextToken()) {
                .Void => return try visitor.visitVoid(Error),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            }
        }

        fn visit_seq(self: *Deserializer, len: ?usize, end: Token, visitor: anytype) Error!@TypeOf(visitor).Value {
            var s = DeserializerSeqVisitor{ .de = self, .len = len, .end = end };
            var value = visitor.visitSequence(s.sequenceAccess());

            try assertNextToken(self, end);

            return value;
        }

        fn assertNextToken(self: *Deserializer, expected: Token) !void {
            if (self.nextTokenOpt()) |token| {
                const token_tag = std.meta.activeTag(token);
                const expected_tag = std.meta.activeTag(expected);

                if (token_tag == expected_tag) {
                    switch (token) {
                        //.MapEnd => try expectEqual(@field(token, "MapEnd"), @field(expected, "MapEnd")),
                        .SeqEnd => try expectEqual(@field(token, "SeqEnd"), @field(expected, "SeqEnd")),
                        //.Struct => try expectEqual(@field(token, "MapEnd"), @field(expected, "MapEnd")),
                        else => @panic("unexpected token"),
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

const DeserializerSeqVisitor = struct {
    de: *Deserializer,
    len: ?usize,
    end: Token,

    const Self = @This();
    const impl = @"impl DeserializerSeqVisitor";

    pub usingnamespace getty.de.SequenceAccess(
        *Self,
        impl.sequenceAccess.Error,
        impl.sequenceAccess.nextElementSeed,
    );
};

const @"impl DeserializerSeqVisitor" = struct {
    pub const sequenceAccess = struct {
        pub const Error = @"impl Deserializer".deserializer.Error;

        pub fn nextElementSeed(self: *DeserializerSeqVisitor, seed: anytype) Error!?@TypeOf(seed).Value {
            if (self.de.peekTokenOpt()) |token| {
                if (std.meta.eql(token, self.end)) return null;
            }

            self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

            return try seed.deserialize(self.de.allocator, self.de.deserializer());
        }
    };
};
