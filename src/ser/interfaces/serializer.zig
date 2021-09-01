/// A data format that can serialize any data type supported by Getty.
///
/// This interface is generic over the following:
///
///   - An `O` type representing the successful return type of some of
///     `Serializer`'s required methods.
///
///   - An `E` type representing the error set in the return type of
///     all of `Serializer`'s required methods.
///
///   - An `M` type representing a type that implements the `getty.ser.Map`
///     interface.
///
///   - An `SE` type representing a type that implements the
///     `getty.ser.Sequence` interface.
///
///   - An `ST` type representing a type that implements the
///     `getty.ser.Struct` interface.
///
///   - An `T` type representing a type that implements the
///     `getty.ser.Tuple` interface.
///
/// Note that while many required methods take values of `anytype`, due to the
/// checks performed in `serialize`, implementations have compile-time
/// guarantees that the passed-in value is of a type one would naturally
/// expect.
///
/// Data model:
///
///     1. bool
///     2. integer
///     3. float
///     4. string
///     5. option
///     6. void
///     7. variant
///     8. sequence
///     9. map
///     10. struct
///     11. tuple
pub fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime M: type,
    comptime SE: type,
    comptime ST: type,
    comptime T: type,
    comptime boolFn: fn (Context, bool) E!O,
    comptime floatFn: fn (Context, anytype) E!O,
    comptime intFn: fn (Context, anytype) E!O,
    comptime mapFn: fn (Context, ?usize) E!M,
    comptime nullFn: fn (Context) E!O,
    comptime sequenceFn: fn (Context, ?usize) E!SE,
    comptime stringFn: fn (Context, anytype) E!O,
    comptime structFn: fn (Context, comptime []const u8, usize) E!ST,
    comptime tupleFn: fn (Context, ?usize) E!T,
    comptime variantFn: fn (Context, anytype) E!O,
    comptime voidFn: fn (Context) E!O,
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        /// Serialize a boolean value.
        pub fn serializeBool(self: Self, value: bool) Error!Ok {
            return try boolFn(self.context, value);
        }

        /// Serialize a float value.
        pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
            return try floatFn(self.context, value);
        }

        /// Serialize an integer value.
        pub fn serializeInt(self: Self, value: anytype) Error!Ok {
            return try intFn(self.context, value);
        }

        // Serialize a map value.
        pub fn serializeMap(self: Self, length: ?usize) Error!M {
            return try mapFn(self.context, length);
        }

        /// Serialize a null value.
        pub fn serializeNull(self: Self) Error!Ok {
            return try nullFn(self.context);
        }

        /// Serialize a variably sized heterogeneous sequence of valueserializer.
        pub fn serializeSequence(self: Self, length: ?usize) Error!SE {
            return try sequenceFn(self.context, length);
        }

        /// Serialize a string value.
        pub fn serializeString(self: Self, value: anytype) Error!Ok {
            return try stringFn(self.context, value);
        }

        // Serialize a struct value.
        pub fn serializeStruct(self: Self, comptime name: []const u8, length: usize) Error!ST {
            return try structFn(self.context, name, length);
        }

        pub fn serializeTuple(self: Self, length: ?usize) Error!T {
            return try tupleFn(self.context, length);
        }

        // Serialize an enum value.
        pub fn serializeVariant(self: Self, value: anytype) Error!Ok {
            return try variantFn(self.context, value);
        }

        // Serialize a void value.
        pub fn serializeVoid(self: Self) Error!Ok {
            return try voidFn(self.context);
        }
    };
}
