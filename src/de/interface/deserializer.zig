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
    comptime mapFn: @TypeOf(struct {
        fn f(c: Context, a: *Allocator, v: anytype) E!@TypeOf(v).Value {
            _ = c;
            _ = a;
            unreachable;
        }
    }.f),
    comptime optionalFn: @TypeOf(struct {
        fn f(c: Context, a: ?*Allocator, v: anytype) E!@TypeOf(v).Value {
            _ = c;
            _ = a;
            unreachable;
        }
    }.f),
    comptime sequenceFn: @TypeOf(struct {
        fn f(c: Context, a: ?*Allocator, v: anytype) E!@TypeOf(v).Value {
            _ = c;
            _ = a;
            unreachable;
        }
    }.f),
    comptime sliceFn: @TypeOf(struct {
        fn f(c: Context, a: *Allocator, v: anytype) E!@TypeOf(v).Value {
            _ = c;
            _ = a;
            unreachable;
        }
    }.f),
    comptime structFn: @TypeOf(struct {
        fn f(c: Context, a: ?*Allocator, v: anytype) E!@TypeOf(v).Value {
            _ = c;
            _ = a;
            unreachable;
        }
    }.f),
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

        pub fn deserializeMap(self: Self, allocator: ?*Allocator, visitor: anytype) E!@TypeOf(visitor).Value {
            return try mapFn(self.context, allocator, visitor);
        }

        pub fn deserializeOptional(self: Self, allocator: ?*Allocator, visitor: anytype) E!@TypeOf(visitor).Value {
            return try optionalFn(self.context, allocator, visitor);
        }

        pub fn deserializeSequence(self: Self, allocator: ?*Allocator, visitor: anytype) E!@TypeOf(visitor).Value {
            return try sequenceFn(self.context, allocator, visitor);
        }

        pub fn deserializeSlice(self: Self, allocator: *Allocator, visitor: anytype) E!@TypeOf(visitor).Value {
            return try sliceFn(self.context, allocator, visitor);
        }

        pub fn deserializeStruct(self: Self, allocator: ?*Allocator, visitor: anytype) E!@TypeOf(visitor).Value {
            return try structFn(self.context, allocator, visitor);
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
