const std = @import("std");

const getty = @import("getty");

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const Token = @import("common/token.zig").Token;

pub const Serializer = struct {
    tokens: []const Token,

    const Self = @This();
    const impl = @"impl Serializer";

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

    pub usingnamespace getty.Serializer(
        *Self,
        impl.@"getty.Serializer".Ok,
        impl.@"getty.Serializer".Error,
        getty.ser.default_with,
        impl.@"getty.Serializer".Map,
        impl.@"getty.Serializer".Seq,
        impl.@"getty.Serializer".Structure,
        impl.@"getty.Serializer".Tuple,
        impl.@"getty.Serializer".serializeBool,
        impl.@"getty.Serializer".serializeEnum,
        impl.@"getty.Serializer".serializeFloat,
        impl.@"getty.Serializer".serializeInt,
        impl.@"getty.Serializer".serializeMap,
        impl.@"getty.Serializer".serializeNull,
        impl.@"getty.Serializer".serializeSeq,
        impl.@"getty.Serializer".serializeSome,
        impl.@"getty.Serializer".serializeString,
        impl.@"getty.Serializer".serializeStruct,
        impl.@"getty.Serializer".serializeTuple,
        impl.@"getty.Serializer".serializeVoid,
    );

    pub usingnamespace getty.ser.Map(
        *Self,
        impl.@"getty.ser.Map".Ok,
        impl.@"getty.ser.Map".Error,
        impl.@"getty.ser.Map".serializeKey,
        impl.@"getty.ser.Map".serializeValue,
        impl.@"getty.ser.Map".end,
    );

    pub usingnamespace getty.ser.Seq(
        *Self,
        impl.@"getty.ser.Seq".Ok,
        impl.@"getty.ser.Seq".Error,
        impl.@"getty.ser.Seq".serializeElement,
        impl.@"getty.ser.Seq".end,
    );

    pub usingnamespace getty.ser.Tuple(
        *Self,
        impl.@"getty.ser.Tuple".Ok,
        impl.@"getty.ser.Tuple".Error,
        impl.@"getty.ser.Tuple".serializeElement,
        impl.@"getty.ser.Tuple".end,
    );

    pub usingnamespace getty.ser.Structure(
        *Self,
        impl.@"getty.ser.Structure".Ok,
        impl.@"getty.ser.Structure".Error,
        impl.@"getty.ser.Structure".serializeField,
        impl.@"getty.ser.Structure".end,
    );
};

const @"impl Serializer" = struct {
    pub const @"getty.Serializer" = struct {
        pub const Ok = void;
        pub const Error = std.mem.Allocator.Error || error{TestExpectedEqual};

        pub const Map = *Serializer;
        pub const Seq = *Serializer;
        pub const Structure = *Serializer;
        pub const Tuple = *Serializer;

        pub fn serializeBool(self: *Serializer, v: bool) Error!Ok {
            try assertNextToken(self, Token{ .Bool = v });
        }

        pub fn serializeEnum(self: *Serializer, v: anytype) Error!Ok {
            const name = switch (@typeInfo(@TypeOf(v))) {
                .EnumLiteral => "",
                .Enum => @typeName(@TypeOf(v)),
                else => unreachable,
            };

            try assertNextToken(self, Token{ .Enum = .{ .name = name, .variant = @tagName(v) } });
        }

        pub fn serializeFloat(self: *Serializer, v: anytype) Error!Ok {
            var expected = switch (@typeInfo(@TypeOf(v))) {
                .ComptimeFloat => Token{ .ComptimeFloat = {} },
                .Float => |info| switch (info.bits) {
                    16 => Token{ .F16 = v },
                    32 => Token{ .F32 = v },
                    64 => Token{ .F64 = v },
                    128 => Token{ .F128 = v },
                    else => @panic("unexpected float size"),
                },
                else => @panic("unexpected type"),
            };

            try assertNextToken(self, expected);
        }

        pub fn serializeInt(self: *Serializer, v: anytype) Error!Ok {
            var expected = switch (@typeInfo(@TypeOf(v))) {
                .ComptimeInt => Token{ .ComptimeInt = {} },
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
                else => @panic("unexpected type"),
            };

            try assertNextToken(self, expected);
        }

        pub fn serializeMap(self: *Serializer, length: ?usize) Error!Map {
            try assertNextToken(self, Token{ .Map = .{ .len = length } });
            return self;
        }

        pub fn serializeNull(self: *Serializer) Error!Ok {
            try assertNextToken(self, Token{ .Null = {} });
        }

        pub fn serializeSeq(self: *Serializer, length: ?usize) Error!Seq {
            try assertNextToken(self, Token{ .Seq = .{ .len = length } });
            return self;
        }

        pub fn serializeSome(self: *Serializer, v: anytype) Error!Ok {
            try assertNextToken(self, Token{ .Some = {} });
            try getty.serialize(v, self.serializer());
        }

        pub fn serializeString(self: *Serializer, v: anytype) Error!Ok {
            try assertNextToken(self, Token{ .String = v });
        }

        pub fn serializeStruct(self: *Serializer, comptime name: []const u8, length: usize) Error!Structure {
            try assertNextToken(self, Token{ .Struct = .{ .name = name, .len = length } });
            return self;
        }

        pub fn serializeTuple(self: *Serializer, length: ?usize) Error!Tuple {
            try assertNextToken(self, Token{ .Tuple = .{ .len = length.? } });
            return self;
        }

        pub fn serializeVoid(self: *Serializer) Error!Ok {
            try assertNextToken(self, Token{ .Void = {} });
        }
    };

    pub const @"getty.ser.Map" = struct {
        pub const Ok = @"getty.Serializer".Ok;
        pub const Error = @"getty.Serializer".Error;

        pub fn serializeKey(self: *Serializer, key: anytype) Error!void {
            try getty.serialize(key, self.serializer());
        }

        pub fn serializeValue(self: *Serializer, value: anytype) Error!void {
            try getty.serialize(value, self.serializer());
        }

        pub fn end(self: *Serializer) Error!Ok {
            try assertNextToken(self, Token{ .MapEnd = {} });
        }
    };

    pub const @"getty.ser.Seq" = struct {
        pub const Ok = @"getty.Serializer".Ok;
        pub const Error = @"getty.Serializer".Error;

        pub fn serializeElement(self: *Serializer, value: anytype) Error!void {
            try getty.serialize(value, self.serializer());
        }

        pub fn end(self: *Serializer) Error!Ok {
            try assertNextToken(self, Token{ .SeqEnd = {} });
        }
    };

    pub const @"getty.ser.Structure" = struct {
        pub const Ok = @"getty.Serializer".Ok;
        pub const Error = @"getty.Serializer".Error;

        pub fn serializeField(self: *Serializer, comptime key: []const u8, value: anytype) Error!Ok {
            try assertNextToken(self, Token{ .String = key });
            try getty.serialize(value, self.serializer());
        }

        pub fn end(self: *Serializer) Error!Ok {
            try assertNextToken(self, Token{ .StructEnd = {} });
        }
    };

    pub const @"getty.ser.Tuple" = struct {
        pub const Ok = @"getty.Serializer".Ok;
        pub const Error = @"getty.Serializer".Error;

        pub fn serializeElement(self: *Serializer, value: anytype) Error!void {
            try getty.serialize(value, self.serializer());
        }

        pub fn end(self: *Serializer) Error!Ok {
            try assertNextToken(self, Token{ .TupleEnd = {} });
        }
    };

    fn assertNextToken(ser: *Serializer, expected: Token) !void {
        if (ser.nextTokenOpt()) |token| {
            const token_tag = std.meta.activeTag(token);
            const expected_tag = std.meta.activeTag(expected);

            if (token_tag == expected_tag) {
                switch (token) {
                    .Bool => try expectEqual(@field(token, "Bool"), @field(expected, "Bool")),
                    .ComptimeFloat => try expectEqual(@field(token, "ComptimeFloat"), @field(expected, "ComptimeFloat")),
                    .ComptimeInt => try expectEqual(@field(token, "ComptimeInt"), @field(expected, "ComptimeInt")),
                    .Enum => {
                        const t = @field(token, "Enum");
                        const e = @field(expected, "Enum");

                        try expectEqualSlices(u8, t.name, e.name);
                        try expectEqualSlices(u8, t.variant, e.variant);
                    },
                    .F16 => try expectEqual(@field(token, "F16"), @field(expected, "F16")),
                    .F32 => try expectEqual(@field(token, "F32"), @field(expected, "F32")),
                    .F64 => try expectEqual(@field(token, "F64"), @field(expected, "F64")),
                    .F128 => try expectEqual(@field(token, "F128"), @field(expected, "F128")),
                    .I8 => try expectEqual(@field(token, "I8"), @field(expected, "I8")),
                    .I16 => try expectEqual(@field(token, "I16"), @field(expected, "I16")),
                    .I32 => try expectEqual(@field(token, "I32"), @field(expected, "I32")),
                    .I64 => try expectEqual(@field(token, "I64"), @field(expected, "I64")),
                    .I128 => try expectEqual(@field(token, "I128"), @field(expected, "I128")),
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
                    .U128 => try expectEqual(@field(token, "U128"), @field(expected, "U128")),
                    .Void => try expectEqual(@field(token, "Void"), @field(expected, "Void")),
                }
            } else {
                @panic("expected Token::{} but serialized as {}");
            }
        } else {
            @panic("expected end of tokens, but {} was serialized");
        }
    }
};
