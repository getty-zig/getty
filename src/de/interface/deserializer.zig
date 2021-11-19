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
    comptime Error: type,
    comptime deserializeBool: Fn(Context, Error),
    comptime deserializeEnum: Fn(Context, Error),
    comptime deserializeFloat: Fn(Context, Error),
    comptime deserializeInt: Fn(Context, Error),
    comptime deserializeMap: Fn(Context, Error),
    comptime deserializeOptional: Fn(Context, Error),
    comptime deserializeSequence: Fn(Context, Error),
    comptime deserializeString: Fn(Context, Error),
    comptime deserializeStruct: Fn(Context, Error),
    comptime deserializeVoid: Fn(Context, Error),
) type {
    return struct {
        pub const @"getty.Deserializer" = struct {
            context: Context,

            const Self = @This();

            pub const Error = Error;

            pub fn deserializeBool(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeBool(self.context, visitor);
            }

            pub fn deserializeEnum(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeEnum(self.context, visitor);
            }

            pub fn deserializeFloat(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeFloat(self.context, visitor);
            }

            pub fn deserializeInt(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeInt(self.context, visitor);
            }

            pub fn deserializeMap(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeMap(self.context, visitor);
            }

            pub fn deserializeOptional(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeOptional(self.context, visitor);
            }

            pub fn deserializeSequence(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeSequence(self.context, visitor);
            }

            pub fn deserializeString(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeString(self.context, visitor);
            }

            pub fn deserializeStruct(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeStruct(self.context, visitor);
            }

            pub fn deserializeVoid(self: Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return try deserializeVoid(self.context, visitor);
            }
        };

        pub fn deserializer(self: Context) @"getty.Deserializer" {
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
