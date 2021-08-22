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

fn DeserializerFn(comptime Context: type, comptime Error: type) type {
    const S = struct {
        fn f(_: Context, visitor: anytype) Error!@TypeOf(visitor).Value {
            unreachable;
        }
    };

    return @TypeOf(S.f);
}
