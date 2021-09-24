const Allocator = @import("std").mem.Allocator;

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
///   - enum
///   - float
///   - int
///   - map
///   - optional
///   - sequence
///   - string
///   - struct
///   - void
pub fn Deserializer(
    comptime Context: type,
    comptime E: type,
    comptime boolFn: Fn(Context, E),
    comptime enumFn: Fn(Context, E),
    comptime floatFn: Fn(Context, E),
    comptime intFn: Fn(Context, E),
    comptime mapFn: Fn(Context, E),
    comptime optionalFn: Fn(Context, E),
    comptime sequenceFn: Fn(Context, E),
    comptime sliceFn: Fn(Context, E),
    comptime structFn: Fn(Context, E),
    comptime voidFn: Fn(Context, E),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        pub const Error = E;

        pub fn deserializeBool(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try boolFn(self.context, visitor);
        }

        pub fn deserializeEnum(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try enumFn(self.context, visitor);
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

        pub fn deserializeSlice(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try sliceFn(self.context, visitor);
        }

        pub fn deserializeStruct(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try structFn(self.context, visitor);
        }

        pub fn deserializeVoid(self: Self, visitor: anytype) E!@TypeOf(visitor).Value {
            return try voidFn(self.context, visitor);
        }
    };

    return struct {
        pub fn deserializer(self: Context) T {
            return .{ .context = self };
        }
    };
}

fn Fn(comptime Context: type, comptime Error: type) type {
    const S = struct {
        fn f(_: Context, visitor: anytype) Error!@TypeOf(visitor).Value {
            unreachable;
        }
    };

    return @TypeOf(S.f);
}
