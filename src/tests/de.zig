const std = @import("std");
const de = @import("getty").de;

const meta = std.meta;
const trait = meta.trait;
const testing = std.testing;

const Token = enum {
    Bool,
    Enum,
    Float,
    Int,
    //Map,
    Null,
    Some,
    Sequence,
    String,
    //Struct,
    Void,
};

/// A data format that deserializes `Token` values.
const Deserializer = struct {
    value: Token,

    const Self = @This();

    const boolValue = true;
    const floatValue = 1.0;
    const intValue = 1;
    const enumValue = .Foobar;
    const stringValue = "Foobar";

    pub fn init(token: Token) Self {
        return .{ .value = token };
    }

    /// Implements `getty.de.Deserializer`.
    pub fn deserializer(self: *Self) D {
        return .{ .context = self };
    }

    const D = de.Deserializer(
        *Self,
        _D.Error,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
        _D.deserializeAny,
    );

    const _D = struct {
        const Error = error{Input};

        fn deserializeAny(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
            return switch (self.value) {
                .Bool => visitor.visitBool(Error, boolValue),
                .Float => visitor.visitFloat(Error, floatValue),
                .Int => visitor.visitInt(Error, intValue),
                //.Map => ,
                .Null => visitor.visitNull(Error),
                .Sequence => blk: {
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
                        d: D,

                        const SV = @This();

                        /// Implements `getty.de.SequenceAccess`.
                        pub fn sequenceAccess(sv: *SV) SA {
                            return .{ .context = sv };
                        }

                        const SA = de.SequenceAccess(
                            *SV,
                            Error,
                            _SA.nextElementSeed,
                        );

                        const _SA = struct {
                            fn nextElementSeed(sv: *SV, seed: anytype) Error!?@TypeOf(seed).Value {
                                sv.d.context.value = .Bool;

                                // Immediately deserialize because we know the
                                // token is `Token.Sequence` at this point, so
                                // there's no parsing to be done.
                                return try seed.deserialize(sv.d);
                            }
                        };
                    }{ .d = self.deserializer() };
                    const sa = sequenceValue.sequenceAccess();

                    break :blk try visitor.visitSequence(sa);
                },
                .Some => visitor.visitSome(self.deserializer()),
                .String => visitor.visitString(Error, stringValue),
                //.Struct => ,
                .Enum => visitor.visitEnum(Error, enumValue),
                .Void => visitor.visitVoid(Error),
            } catch Error.Input;
        }
    };
};

/// A visitor that produces `true` for every input.
pub const TrueVisitor = struct {
    const Self = @This();

    /// Implements `getty.de.Visitor`.
    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    const V = de.Visitor(
        *Self,
        _V.Value,
        _V.visitBool,
        _V.visitEnum,
        _V.visitFloat,
        _V.visitInt,
        _V.visitMap,
        _V.visitNull,
        _V.visitSequence,
        _V.visitSome,
        _V.visitString,
        _V.visitVoid,
    );

    const _V = struct {
        const Value = bool;

        fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
            _ = self;
            _ = input;

            return true;
        }

        fn visitEnum(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            return true;
        }

        fn visitFloat(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            return true;
        }

        fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            return true;
        }

        fn visitMap(self: *Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;

            return true;
        }

        fn visitNull(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            return true;
        }

        // When this is called, the visitor knows how to access elements of the
        // sequence, but the elements aren't yet deserialized. Thus, we need to:
        //
        //   1. Access them (via `nextElementSeed`).
        //
        //   2. Deserialize them into Getty's data model (in `nextelementSeed`
        //      and by a deserializer within a `DeserializeSeed`).
        //
        //   3. Deserialize them once more into the visitor's value.
        fn visitSequence(self: *Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            _ = self;

            return (try sequenceAccess.nextElement(Value)).?;
        }

        fn visitSome(self: *Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;

            return true;
        }

        fn visitString(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            return true;
        }

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            return true;
        }
    };
};

test "Integration" {
    inline for (std.meta.fields(Token)) |field| {
        const input = @intToEnum(Token, field.value);

        if (input == .Sequence) {
            var deserializer = Deserializer.init(input);
            const d = deserializer.deserializer();

            var visitor = TrueVisitor{};
            const v = visitor.visitor();

            try testing.expectEqual(true, try d.deserializeAny(v));
        }
    }
}

comptime {
    testing.refAllDecls(@This());
}
