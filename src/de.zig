const std = @import("std");

const testing = std.testing;

fn DeserializerFn(comptime Context: type, comptime Error: type) type {
    const S = struct {
        fn f(_: Context, visitor: anytype) Error!@TypeOf(visitor).Value {
            unreachable;
        }
    };

    return @TypeOf(S.f);
}

/// A data format that can deserialize any data type supported by Getty.
///
/// This interface is generic over the following:
///
///   - An `E` type representing the error set in the return type of
///     all of `Deserializer`'s required methods.
///
/// Data model:
///
///   - bool
///   - float
///   - identifier
///   - int
///   - map
///   - optional
///   - sequence
///   - string
///   - struct
///   - tuple
///   - variant
///   - void
pub fn Deserializer(
    comptime Context: type,
    comptime E: type,
    comptime anyFn: DeserializerFn(Context, E),
    comptime boolFn: DeserializerFn(Context, E),
    comptime floatFn: DeserializerFn(Context, E),
    //comptime identifierFn: DeserializerFn(Context, E),
    comptime intFn: DeserializerFn(Context, E),
    comptime mapFn: DeserializerFn(Context, E),
    comptime optionalFn: DeserializerFn(Context, E),
    comptime sequenceFn: DeserializerFn(Context, E),
    comptime stringFn: DeserializerFn(Context, E),
    comptime structFn: DeserializerFn(Context, E),
    //comptime tupleFn: DeserializerFn(Context, E),
    comptime variantFn: DeserializerFn(Context, E),
    comptime voidFn: DeserializerFn(Context, E),
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Error = E;

        pub fn deserializeAny(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try anyFn(self.context, visitor);
        }

        pub fn deserializeBool(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try boolFn(self.context, visitor);
        }

        pub fn deserializeFloat(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try floatFn(self.context, visitor);
        }

        pub fn deserializeInt(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try intFn(self.context, visitor);
        }

        pub fn deserializeMap(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try mapFn(self.context, visitor);
        }

        pub fn deserializeOptional(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try optionalFn(self.context, visitor);
        }

        pub fn deserializeSequence(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try sequenceFn(self.context, visitor);
        }

        pub fn deserializeString(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try stringFn(self.context, visitor);
        }

        pub fn deserializeStruct(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try structFn(self.context, visitor);
        }

        pub fn deserializeVariant(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try variantFn(self.context, visitor);
        }

        pub fn deserializeVoid(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try voidFn(self.context, visitor);
        }
    };
}

pub fn Visitor(
    comptime Context: type,
    comptime V: type,
    comptime boolFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: bool) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime floatFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: anytype) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime intFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: anytype) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime mapFn: @TypeOf(struct {
        fn f(c: Context, m: anytype) @TypeOf(m).Error!V {
            _ = c;
            _ = m;
            unreachable;
        }
    }.f),
    comptime nullFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type) Error!V {
            _ = c;
            unreachable;
        }
    }.f),
    comptime sequenceFn: @TypeOf(struct {
        fn f(c: Context, s: anytype) @TypeOf(s).Error!V {
            _ = c;
            _ = s;
            unreachable;
        }
    }.f),
    comptime someFn: @TypeOf(struct {
        fn f(c: Context, d: anytype) @TypeOf(d).Error!V {
            _ = c;
            _ = d;
            unreachable;
        }
    }.f),
    comptime stringFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: anytype) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime variantFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: anytype) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime voidFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type) Error!V {
            _ = c;
            unreachable;
        }
    }.f),
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Value = V;

        pub fn visitBool(self: Self, comptime Error: type, input: bool) Error!Value {
            return try boolFn(self.context, Error, input);
        }

        pub fn visitFloat(self: Self, comptime Error: type, input: anytype) Error!Value {
            return try floatFn(self.context, Error, input);
        }

        pub fn visitInt(self: Self, comptime Error: type, input: anytype) Error!Value {
            return try intFn(self.context, Error, input);
        }

        pub fn visitMap(self: Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            return try mapFn(self.context, mapAccess);
        }

        pub fn visitNull(self: Self, comptime Error: type) Error!Value {
            return try nullFn(self.context, Error);
        }

        pub fn visitSequence(self: Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            return try sequenceFn(self.context, sequenceAccess);
        }

        // TODO: what is the point of visitSome?
        pub fn visitSome(self: Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try someFn(self.context, deserializer);
        }

        pub fn visitString(self: Self, comptime Error: type, input: anytype) Error!Value {
            return try stringFn(self.context, Error, input);
        }

        pub fn visitVariant(self: Self, comptime Error: type, input: anytype) Error!Value {
            return try variantFn(self.context, Error, input);
        }

        pub fn visitVoid(self: Self, comptime Error: type) Error!Value {
            return try voidFn(self.context, Error);
        }
    };
}

pub fn SequenceAccess(
    comptime Context: type,
    comptime E: type,
    comptime nextElementSeedFn: @TypeOf(struct {
        fn f(c: Context, seed: anytype) E!?@TypeOf(seed).Value {
            _ = c;
            unreachable;
        }
    }.f),
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Error = E;

        pub fn nextElementSeed(self: Self, seed: anytype) Error!?@TypeOf(seed).Value {
            return try nextElementSeedFn(self.context, seed);
        }
    };
}

pub fn DeserializeSeed(
    comptime Context: type,
    comptime V: type,
    comptime deserializeFn: @TypeOf(struct {
        fn f(c: Context, d: anytype) @TypeOf(d).Error!Value {
            _ = c;
            unreachable;
        }
    }.f),
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Value = V;

        pub fn deserialize(self: Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try deserializeFn(self.context, deserializer);
        }
    };
}

pub const VoidVisitor = struct {
    const Self = @This();

    /// Implements `getty.de.Visitor`.
    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    const V = Visitor(
        *Self,
        _V.Value,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        _V.visitVoid,
    );

    const _V = struct {
        const Value = void;

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            return {};
        }
    };
};

pub const BoolVisitor = struct {
    const Self = @This();

    /// Implements `getty.de.Visitor`.
    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    const V = Visitor(
        *Self,
        _V.Value,
        _V.visitBool,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const _V = struct {
        const Value = bool;

        fn visitBool(self: *Self, comptime Error: type, value: bool) Error!Value {
            _ = self;

            return value;
        }
    };
};

pub fn FloatVisitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub fn visitor(self: *Self) V {
            return .{ .context = self };
        }

        const V = Visitor(
            *Self,
            _V.Value,
            undefined,
            _V.visitFloat,
            _V.visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        const _V = struct {
            const Value = T;

            fn visitFloat(self: *Self, comptime Error: type, value: anytype) Error!Value {
                _ = self;

                // This cast is safe, but it may cause the numeric value to
                // lose precision.
                return @floatCast(T, value);
            }

            fn visitInt(self: *Self, comptime Error: type, value: anytype) Error!Value {
                _ = self;

                // This cast is always safe.
                return @intToFloat(T, value);
            }
        };
    };
}

pub fn IntVisitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub fn visitor(self: *Self) V {
            return .{ .context = self };
        }

        const V = Visitor(
            *Self,
            _V.Value,
            undefined,
            undefined,
            _V.visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        const _V = struct {
            const Value = T;

            fn visitInt(self: *Self, comptime Error: type, value: anytype) Error!Value {
                _ = self;

                return std.math.cast(T, value) catch |err| switch (err) {
                    error.Overflow => Error.DeserializationError,
                };
            }
        };
    };
}

pub fn deserialize(comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
    var visitor = switch (@typeInfo(T)) {
        .Bool => BoolVisitor{},
        .Float => FloatVisitor(T){},
        .Int => IntVisitor(T){},
        .Void => VoidVisitor{},
        else => unreachable,
    };

    return try deserializer.deserializeAny(visitor.visitor());
}

comptime {
    testing.refAllDecls(@This());
}
