const std = @import("std");
const getty = @import("getty");

const meta = std.meta;
const trait = meta.trait;
const testing = std.testing;

const Token = union(enum) {
    Bool: bool,
    Enum: enum { foo, bar },
    Float: f32,
    Int: i64,
    //Map,
    Null,
    Some,
    Sequence,
    String: []const u8,
    //Struct,
    Void: void,
};

/// A data format that deserializes `Token` values.
const Deserializer = struct {
    value: Token,

    const Self = @This();

    const stringValue = "Foobar";

    pub fn init(token: Token) Self {
        return .{ .value = token };
    }

    /// Implements `getty.de.Deserializer`.
    pub usingnamespace getty.de.Deserializer(
        *Self,
        _D.Error,
        _D.deserializeBool,
        _D.deserializeEnum,
        _D.deserializeFloat,
        _D.deserializeInt,
        undefined, // map
        _D.deserializeOptional,
        _D.deserializeSequence,
        _D.deserializeString,
        undefined, // struct
        _D.deserializeVoid,
    );

    const _D = struct {
        const Error = error{Input};

        fn deserializeBool(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Bool => |value| try visitor.visitBool(Error, value),
                else => Error.Input,
            };
        }

        fn deserializeEnum(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Enum => |value| try visitor.visitEnum(Error, value),
                else => Error.Input,
            };
        }

        fn deserializeFloat(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Float => |value| try visitor.visitFloat(Error, value),
                .Int => |value| try visitor.visitInt(Error, value),
                else => Error.Input,
            };
        }

        fn deserializeInt(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Float => |value| try visitor.visitFloat(Error, value),
                .Int => |value| try visitor.visitInt(Error, value),
                else => Error.Input,
            };
        }

        fn deserializeOptional(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Null => try visitor.visitNull(Error),
                .Some => try visitor.visitSome(self.deserializer()),
                else => Error.Input,
            };
        }

        fn deserializeSequence(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            if (self.value != .Sequence) {
                return Error.Input;
            }

            // Example:
            //
            // For the sequence [1, 2, 3], `nextElementSeed` would do the following:
            //
            //   1. If ']' is encountered, `null` is returned to
            //      indicate the end of the sequence.
            //
            //   2. If an element is encountered, then it is
            //      deserialized and the deserialized value is returned.
            //
            //   3. If ',' is encountered, the comma and any subsequent
            //      whitespace is eaten. If ']' is encountered, an
            //      error is returned for having a trailing comma. If,
            //      instead, an element is encountered, then go to 2).
            var sequenceValue = struct {
                d: @typeInfo(@TypeOf(Self)).Fn.return_type.?,

                const SV = @This();

                /// Implements `getty.de.SeqAccess`.
                pub usingnamespace getty.de.SeqAccess(
                    *SV,
                    Error,
                    _SA.nextElementSeed,
                );

                const _SA = struct {
                    fn nextElementSeed(sv: *SV, seed: anytype) !?@TypeOf(seed).Value {
                        sv.d.context.value = .Bool;

                        // Immediately deserialize because we know the
                        // token is `Token.Sequence` at this point, so
                        // there's no parsing to be done.
                        return try seed.deserialize(sv.d);
                    }
                };
            }{ .d = self.deserializer() };
            const sa = sequenceValue.seqAccess();

            return try visitor.visitSequence(sa);
        }

        fn deserializeString(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .String => try visitor.visitString(Error, stringValue),
                else => Error.Input,
            };
        }

        fn deserializeVoid(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Void => try visitor.visitVoid(Error),
                else => Error.Input,
            };
        }
    };
};

test "bool" {
    {
        var d = Deserializer.init(Token{ .Bool = true });
        try testing.expectEqual(true, try getty.deserialize(bool, d.deserializer()));
    }

    {
        var d = Deserializer.init(Token{ .Bool = false });
        try testing.expectEqual(false, try getty.deserialize(bool, d.deserializer()));
    }
}

test "int" {
    {
        var d = Deserializer.init(Token{ .Int = 42 });
        try testing.expectEqual(@as(i64, 42), try getty.deserialize(i64, d.deserializer()));
    }

    {
        var d = Deserializer.init(Token{ .Int = 42 });
        try testing.expectEqual(@as(i128, 42), try getty.deserialize(i128, d.deserializer()));
    }

    {
        var d = Deserializer.init(Token{ .Float = 42.0 });
        try testing.expectEqual(@as(i64, 42), try getty.deserialize(i64, d.deserializer()));
    }

    {
        var d = Deserializer.init(Token{ .Float = 42.0 });
        try testing.expectEqual(@as(i128, 42.0), try getty.deserialize(i128, d.deserializer()));
    }
}

test "float" {
    //{
    //var d = Deserializer.init(Token{ .Float = 3.14 });
    //try testing.expectEqual(@floatCast(f64, 3.14), try getty.deserialize(f64, d.deserializer()));
    //}

    //{
    //var d = Deserializer.init(Token{ .Float = 3.14 });
    //try testing.expectEqual(@floatCast(f128, 3.14), try getty.deserialize(f128, d.deserializer()));
    //}

    {
        var d = Deserializer.init(Token{ .Int = 3 });
        try testing.expectEqual(@intToFloat(f64, 3), try getty.deserialize(f64, d.deserializer()));
    }

    {
        var d = Deserializer.init(Token{ .Int = 3 });
        try testing.expectEqual(@intToFloat(f128, 3), try getty.deserialize(f128, d.deserializer()));
    }
}

test "void" {
    var d = Deserializer.init(Token{ .Void = {} });
    try testing.expectEqual({}, try getty.deserialize(void, d.deserializer()));
}

test {
    testing.refAllDecls(@This());
}
