const concepts = @import("concepts");
const getty = @import("../../lib.zig");
const std = @import("std");

/// Serializer interface.
///
/// Serializers are responsible for the following conversion:
///
///              Getty Data Model
///
///                     |          <-------
///                     ▼                 |
///                                       |
///                Data Format            |
///                                       |
///                                       |
///                                       |
///                                       |
///
///                               `getty.Serializer`
///
/// Notice how Zig data is not a part of this conversion. Serializers only
/// convert values that fall under Getty's data model. In other words, a Getty
/// serializer specifies how to convert a Getty map into a JSON map, not how to
/// convert a `struct { x: i32 }` to a JSON map.
///
/// Most types within Getty's data model have the same semantics as their Zig
/// counterparts. For example, Getty booleans are functionally equivalent to
/// `bool` values and Getty integers are just regular Zig integers. Do keep in
/// mind though that there are types that do not have a 1:1 correlation, such
/// as maps and sequences.
///
/// Parameters
/// ==========
///
///     Context
///     -------
///
///         This is the type that implements `getty.Serializer` (or a pointer to it).
///
///     Ok
///     --
///
///         The successful return type for a majority of `getty.Serializer`'s methods.
///
///     Error
///     -----
///
///         The error set used by all of `getty.Serializer`'s methods upon failure.
///
///     user_sbt
///     --------
///
///         A Serialization Block or Tuple.
///
///         This parameter is intended for users of a serializer, enabling them
///         to use their own custom serialization logic.
///
///     ser_sbt
///     -------
///
///         A Serialization Block or Tuple.
///
///         This parameter is intended for serializers, enabling them to use
///         their own custom serialization logic.
///
///     Map
///     ---
///
///         A type that implements `getty.ser.Map` (or a pointer to it).
///
///         The `getty.ser.Map` interface specifies how to serialize the
///         components of a map and how to finish serialization for maps.
///
///     Seq
///     ---
///
///         A type that implements `getty.ser.Seq` (or a pointer to it).
///
///         The `getty.ser.Seq` interface specifies how to serialize the
///         elements of a sequence and how to finish serialization for
///         sequences.
///
///     Struct
///     ------
///
///         A type that implements `getty.ser.Structure` (or a pointer to it).
///
///         The `getty.ser.Structure` interface specifies how to serialize the
///         fields of a struct (e.g., fields) and how to finish serialization
///         for structs.
///
///     Tuple
///     -----
///
///         A type that implements `getty.ser.Tuple` (or a pointer to it).
///
///         The `getty.ser.Tuple` interface specifies how to serialize the
///         elements of a tuple and how to finish serialization for tuples.
///
///     serializeXXX
///     ------------
///
///         Methods required by `getty.Serializer` to carry out serialization.
///         Each method encompasses one or more types within the GDM.
///
///         Most of the methods are one and done (i.e.,  you call them once and
///         in return you get a fully serialized value). However, some methods
///         (specifically, the ones for compound data types like `serializeMap`
///         and `serializeSeq`), only start the serialization process. The
///         caller must then continue where the methods left off by using the
///         returned `getty.ser.Map|Seq|Struct|Tuple` implementation.
pub fn Serializer(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime user_sbt: anytype,
    comptime ser_sbt: anytype,
    comptime Map: type,
    comptime Seq: type,
    comptime Struct: type,
    comptime Tuple: type,
    comptime serializeBool: fn (Context, bool) Error!Ok,
    comptime serializeEnum: fn (Context, anytype) Error!Ok,
    comptime serializeFloat: fn (Context, anytype) Error!Ok,
    comptime serializeInt: fn (Context, anytype) Error!Ok,
    comptime serializeMap: fn (Context, ?usize) Error!Map,
    comptime serializeNull: fn (Context) Error!Ok,
    comptime serializeSeq: fn (Context, ?usize) Error!Seq,
    comptime serializeSome: fn (Context, anytype) Error!Ok,
    comptime serializeString: fn (Context, anytype) Error!Ok,
    comptime serializeStruct: @TypeOf(struct {
        fn f(self: Context, comptime name: []const u8, length: usize) Error!Struct {
            _ = self;
            _ = name;
            _ = length;

            unreachable;
        }
    }.f),
    comptime serializeTuple: fn (Context, ?usize) Error!Tuple,
    comptime serializeVoid: fn (Context) Error!Ok,
) type {
    comptime {
        getty.concepts.@"getty.ser.sbt"(user_sbt);
        getty.concepts.@"getty.ser.sbt"(ser_sbt);

        //TODO: Add concept for Error (blocked by concepts library).
    }

    return struct {
        pub const @"getty.Serializer" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = Ok;

            /// Error set used upon failure.
            pub const Error = Error;

            /// Serialization Tuple associated with the serializer.
            pub const st = blk: {
                const user_st = if (@TypeOf(user_sbt) == type) .{user_sbt} else user_sbt;
                const ser_st = if (@TypeOf(ser_sbt) == type) .{ser_sbt} else ser_sbt;
                const default = getty.default_st;

                const U = @TypeOf(user_st);
                const S = @TypeOf(ser_st);
                const Default = @TypeOf(default);

                if (U == Default and S == Default) {
                    break :blk default;
                } else if (U != Default and S == Default) {
                    break :blk user_st ++ default;
                } else if (U == Default and S != Default) {
                    break :blk ser_st ++ default;
                } else {
                    break :blk user_st ++ ser_st ++ default;
                }
            };

            /// Serializes a `bool` value.
            pub fn serializeBool(self: Self, value: bool) Error!Ok {
                return try serializeBool(self.context, value);
            }

            // Serializes an enum value.
            pub fn serializeEnum(self: Self, value: anytype) Error!Ok {
                // TODO: Replace this with a concept (blocked by concepts library).
                switch (@typeInfo(@TypeOf(value))) {
                    .Enum, .EnumLiteral => {},
                    else => @compileError("expected enum, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
                }

                return try serializeEnum(self.context, value);
            }

            /// Serializes a floating-point value.
            pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
                comptime concepts.float(@TypeOf(value));

                return try serializeFloat(self.context, value);
            }

            /// Serializes an integer value.
            pub fn serializeInt(self: Self, value: anytype) Error!Ok {
                comptime concepts.integral(@TypeOf(value));

                return try serializeInt(self.context, value);
            }

            /// Starts the serialization process for a map.
            pub fn serializeMap(self: Self, length: ?usize) Error!Map {
                return try serializeMap(self.context, length);
            }

            /// Serializes a `null` value.
            pub fn serializeNull(self: Self) Error!Ok {
                return try serializeNull(self.context);
            }

            /// Starts the serialization process for a sequence.
            pub fn serializeSeq(self: Self, length: ?usize) Error!Seq {
                return try serializeSeq(self.context, length);
            }

            /// Serializes the payload of an optional.
            pub fn serializeSome(self: Self, value: anytype) Error!Ok {
                return try serializeSome(self.context, value);
            }

            /// Serializes a string value.
            pub fn serializeString(self: Self, value: anytype) Error!Ok {
                comptime concepts.string(@TypeOf(value));

                return try serializeString(self.context, value);
            }

            /// Starts the serialization process for a struct.
            pub fn serializeStruct(self: Self, comptime name: []const u8, length: usize) Error!Struct {
                return try serializeStruct(self.context, name, length);
            }

            /// Starts the serialization process for a tuple.
            pub fn serializeTuple(self: Self, length: ?usize) Error!Tuple {
                return try serializeTuple(self.context, length);
            }

            /// Serializes a `void` value.
            pub fn serializeVoid(self: Self) Error!Ok {
                return try serializeVoid(self.context);
            }
        };

        pub fn serializer(self: Context) @"getty.Serializer" {
            return .{ .context = self };
        }
    };
}
