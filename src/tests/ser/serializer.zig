const std = @import("std");
const getty = @import("getty");

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const Token = @import("token.zig").Token;

pub const Serializer = struct {
    tokens: []const Token,

    const Self = @This();

    pub fn init(tokens: []const Token) Self {
        return .{ .tokens = tokens };
    }

    pub fn remaining(self: Self) usize {
        return self.tokens.len;
    }

    fn nextToken(self: *Self) ?Token {
        switch (self.remaining()) {
            0 => return null,
            else => |len| {
                const first = self.tokens[0];
                self.tokens = if (len == 1) &[_]Token{} else self.tokens[1..];
                return first;
            },
        }
    }

    pub usingnamespace getty.Serializer(
        *Self,
        Ok,
        Error,
        _S.MapSerialize,
        _S.SequenceSerialize,
        _S.StructSerialize,
        _S.TupleSerialize,
        _S.serializeBool,
        _S.serializeEnum,
        _S.serializeFloat,
        _S.serializeInt,
        _S.serializeMap,
        _S.serializeNull,
        _S.serializeSequence,
        _S.serializeSome,
        _S.serializeString,
        _S.serializeStruct,
        _S.serializeTuple,
        _S.serializeVoid,
    );

    const Ok = void;
    const Error = getty.ser.Error || error{TestExpectedEqual};

    const _S = struct {
        const MapSerialize = *Self;
        const SequenceSerialize = *Self;
        const StructSerialize = *Self;
        const TupleSerialize = *Self;

        fn serializeBool(self: *Self, v: bool) Error!Ok {
            try assertNextToken(self, Token{ .Bool = v });
        }

        fn serializeEnum(self: *Self, v: anytype) Error!Ok {
            const name = switch (@typeInfo(@TypeOf(v))) {
                .EnumLiteral => "",
                .Enum => @typeName(@TypeOf(v)),
                else => unreachable,
            };

            try assertNextToken(self, Token{ .Enum = .{ .name = name, .variant = @tagName(v) } });
        }

        fn serializeFloat(self: *Self, v: anytype) Error!Ok {
            var expected = switch (@typeInfo(@TypeOf(v)).Float.bits) {
                16 => Token{ .F16 = v },
                32 => Token{ .F32 = v },
                64 => Token{ .F64 = v },
                128 => Token{ .F128 = v },
                else => @panic("unexpected float size"),
            };

            try assertNextToken(self, expected);
        }

        fn serializeInt(self: *Self, v: anytype) Error!Ok {
            var expected = switch (@typeInfo(@TypeOf(v))) {
                .Int => |info| switch (info.signedness) {
                    .signed => switch (info.bits) {
                        8 => Token{ .I8 = v },
                        16 => Token{ .I16 = v },
                        32 => Token{ .I32 = v },
                        64 => Token{ .I64 = v },
                        128 => Token{ .I128 = v },
                        else => @panic("unexpected integer size"),
                    },
                    .unsigned => switch (info.bits) {
                        8 => Token{ .U8 = v },
                        16 => Token{ .U16 = v },
                        32 => Token{ .U32 = v },
                        64 => Token{ .U64 = v },
                        128 => Token{ .U128 = v },
                        else => @panic("unexpected integer size"),
                    },
                },
                else => unreachable,
            };

            try assertNextToken(self, expected);
        }

        fn serializeMap(self: *Self, length: ?usize) Error!MapSerialize {
            try assertNextToken(self, Token{ .Map = .{ .len = length } });
            return self;
        }

        fn serializeNull(self: *Self) Error!Ok {
            try assertNextToken(self, Token{ .Null = {} });
        }

        fn serializeSequence(self: *Self, length: ?usize) Error!SequenceSerialize {
            try assertNextToken(self, Token{ .Seq = .{ .len = length } });
            return self;
        }

        fn serializeSome(self: *Self, v: anytype) Error!Ok {
            try assertNextToken(self, Token{ .Some = {} });
            try getty.serialize(v, self.serializer());
        }

        fn serializeString(self: *Self, v: anytype) Error!Ok {
            try assertNextToken(self, Token{ .String = v });
        }

        fn serializeStruct(self: *Self, name: []const u8, length: usize) Error!StructSerialize {
            try assertNextToken(self, Token{ .Struct = .{ .name = name, .len = length } });
            return self;
        }

        fn serializeTuple(self: *Self, length: ?usize) Error!TupleSerialize {
            try assertNextToken(self, Token{ .Tuple = .{ .len = length.? } });
            return self;
        }

        fn serializeVoid(self: *Self) Error!Ok {
            try assertNextToken(self, Token{ .Void = {} });
        }
    };

    pub usingnamespace getty.ser.MapSerialize(
        *Self,
        Ok,
        Error,
        _M.serializeKey,
        _M.serializeValue,
        _M.end,
    );

    const _M = struct {
        fn serializeKey(self: *Self, key: anytype) Error!void {
            try getty.serialize(key, self.serializer());
        }

        fn serializeValue(self: *Self, value: anytype) Error!void {
            try getty.serialize(value, self.serializer());
        }

        fn end(self: *Self) Error!Ok {
            try assertNextToken(self, Token{ .MapEnd = {} });
        }
    };

    pub usingnamespace getty.ser.SequenceSerialize(
        *Self,
        Ok,
        Error,
        _SQ.serializeElement,
        _SQ.end,
    );

    const _SQ = struct {
        fn serializeElement(self: *Self, value: anytype) Error!void {
            try getty.serialize(value, self.serializer());
        }

        fn end(self: *Self) Error!Ok {
            try assertNextToken(self, Token{ .SeqEnd = {} });
        }
    };

    pub usingnamespace getty.ser.TupleSerialize(
        *Self,
        Ok,
        Error,
        _T.serializeElement,
        _T.end,
    );

    const _T = struct {
        fn serializeElement(self: *Self, value: anytype) Error!void {
            try getty.serialize(value, self.serializer());
        }

        fn end(self: *Self) Error!Ok {
            try assertNextToken(self, Token{ .TupleEnd = {} });
        }
    };

    pub usingnamespace getty.ser.StructSerialize(
        *Self,
        Ok,
        Error,
        _ST.serializeField,
        _ST.end,
    );

    const _ST = struct {
        pub fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!Ok {
            try assertNextToken(self, Token{ .String = key });
            try getty.serialize(value, self.serializer());
        }

        fn end(self: *Self) Error!Ok {
            try assertNextToken(self, Token{ .StructEnd = {} });
        }
    };
};

fn assertNextToken(ser: *Serializer, expected: Token) !void {
    if (ser.nextToken()) |token| {
        const token_tag = std.meta.activeTag(token);
        const expected_tag = std.meta.activeTag(expected);

        if (token_tag == expected_tag) {
            switch (token) {
                .Bool => try expectEqual(@field(token, "Bool"), @field(expected, "Bool")),
                .Enum => {
                    const t = @field(token, "Enum");
                    const e = @field(expected, "Enum");

                    try expectEqualSlices(u8, t.name, e.name);
                    try expectEqualSlices(u8, t.variant, e.variant);
                },
                .F16 => try expectEqual(@field(token, "F16"), @field(expected, "F16")),
                .F32 => try expectEqual(@field(token, "F32"), @field(expected, "F32")),
                .F64 => try expectEqual(@field(token, "F64"), @field(expected, "F64")),
                .I8 => try expectEqual(@field(token, "I8"), @field(expected, "I8")),
                .I16 => try expectEqual(@field(token, "I16"), @field(expected, "I16")),
                .I32 => try expectEqual(@field(token, "I32"), @field(expected, "I32")),
                .I64 => try expectEqual(@field(token, "I64"), @field(expected, "I64")),
                .Map => try expectEqual(@field(token, "Map"), @field(expected, "Map")),
                .MapEnd => try expectEqual(@field(token, "MapEnd"), @field(expected, "MapEnd")),
                .Null => try expectEqual(@field(token, "Null"), @field(expected, "Null")),
                .Seq => try expectEqual(@field(token, "Seq"), @field(expected, "Seq")),
                .SeqEnd => try expectEqual(@field(token, "SeqEnd"), @field(expected, "SeqEnd")),
                .Some => try expectEqual(@field(token, "Some"), @field(expected, "Some")),
                .String => try expectEqualSlices(u8, @field(token, "String"), @field(expected, "String")),
                .Struct => {
                    const t = @field(token, "Struct");
                    const e = @field(expected, "Struct");

                    try expectEqualSlices(u8, t.name, e.name);
                    try expectEqual(t.len, e.len);
                },
                .StructEnd => try expectEqual(@field(token, "StructEnd"), @field(expected, "StructEnd")),
                .Tuple => try expectEqual(@field(token, "Tuple"), @field(expected, "Tuple")),
                .TupleEnd => try expectEqual(@field(token, "TupleEnd"), @field(expected, "TupleEnd")),
                .U8 => try expectEqual(@field(token, "U8"), @field(expected, "U8")),
                .U16 => try expectEqual(@field(token, "U16"), @field(expected, "U16")),
                .U32 => try expectEqual(@field(token, "U32"), @field(expected, "U32")),
                .U64 => try expectEqual(@field(token, "U64"), @field(expected, "U64")),
                .Void => try expectEqual(@field(token, "Void"), @field(expected, "Void")),
                else => unreachable,
            }
        } else {
            @panic("expected Token::{} but serialized as {}");
        }
    } else {
        @panic("expected end of tokens, but {} was serialized");
    }
}
