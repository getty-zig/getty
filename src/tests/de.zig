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
                .Bool => try visitor.visitBool(Error, boolValue),
                else => Error.Input,
            };
        }

        fn deserializeEnum(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Enum => try visitor.visitEnum(Error, enumValue),
                else => Error.Input,
            };
        }

        fn deserializeFloat(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Float => try visitor.visitFloat(Error, floatValue),
                else => Error.Input,
            };
        }

        fn deserializeInt(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Int => try visitor.visitInt(Error, intValue),
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
                    fn nextElementSeed(sv: *SV, seed: anytype) !?@TypeOf(seed).Value {
                        sv.d.context.value = .Bool;

                        // Immediately deserialize because we know the
                        // token is `Token.Sequence` at this point, so
                        // there's no parsing to be done.
                        return try seed.deserialize(sv.d);
                    }
                };
            }{ .d = self.deserializer() };
            const sa = sequenceValue.sequenceAccess();

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

        var deserializer = Deserializer.init(input);
        const d = deserializer.deserializer();

        var visitor = TrueVisitor{};
        const v = visitor.visitor();

        switch (input) {
            .Bool => try testing.expectEqual(true, try d.deserializeBool(v)),
            .Enum => try testing.expectEqual(true, try d.deserializeEnum(v)),
            .Float => try testing.expectEqual(true, try d.deserializeFloat(v)),
            .Int => try testing.expectEqual(true, try d.deserializeInt(v)),
            .Null => try testing.expectEqual(true, try d.deserializeOptional(v)),
            .Sequence => try testing.expectEqual(true, try d.deserializeSequence(v)),
            .Some => try testing.expectEqual(true, try d.deserializeOptional(v)),
            .String => try testing.expectEqual(true, try d.deserializeString(v)),
            .Void => try testing.expectEqual(true, try d.deserializeVoid(v)),
        }
    }
}

comptime {
    testing.refAllDecls(@This());
}
