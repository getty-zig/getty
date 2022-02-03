//! Serializer interface.
//!
//! Serializers define how to convert from Getty's data model into a data
//! format.

const std = @import("std");

/// Returns an anonymously namespaced interface function for serializers.
pub fn Serializer(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime ser: type,
    comptime MapSerialize: type,
    comptime SequenceSerialize: type,
    comptime StructSerialize: type,
    comptime TupleSerialize: type,
    comptime serializeBool: fn (Context, bool) Error!Ok,
    comptime serializeEnum: fn (Context, anytype) Error!Ok,
    comptime serializeFloat: fn (Context, anytype) Error!Ok,
    comptime serializeInt: fn (Context, anytype) Error!Ok,
    comptime serializeMap: fn (Context, ?usize) Error!MapSerialize,
    comptime serializeNull: fn (Context) Error!Ok,
    comptime serializeSequence: fn (Context, ?usize) Error!SequenceSerialize,
    comptime serializeSome: fn (Context, anytype) Error!Ok,
    comptime serializeString: fn (Context, anytype) Error!Ok,
    comptime serializeStruct: @TypeOf(struct {
        fn f(self: Context, comptime name: []const u8, length: usize) Error!StructSerialize {
            _ = self;
            _ = name;
            _ = length;

            unreachable;
        }
    }.f),
    comptime serializeTuple: fn (Context, ?usize) Error!TupleSerialize,
    comptime serializeVoid: fn (Context) Error!Ok,
) type {
    return struct {
        pub const @"getty.Serializer" = struct {
            const Self = @This();

            context: Context,

            /// Successful return type.
            pub const Ok = Ok;

            /// The error set used upon failure.
            pub const Error = Error;

            /// TODO
            pub const ser = ser;

            /// Serializes a `bool` value.
            pub fn serializeBool(self: Self, value: bool) Error!Ok {
                return try serializeBool(self.context, value);
            }

            // Serializes an enum value.
            pub fn serializeEnum(self: Self, value: anytype) Error!Ok {
                switch (@typeInfo(@TypeOf(value))) {
                    .Enum, .EnumLiteral => {},
                    else => @compileError("expected enum, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
                }

                return try serializeEnum(self.context, value);
            }

            /// Serializes a floating-point value.
            pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
                comptime if (!std.meta.trait.isFloat(@TypeOf(value))) {
                    @compileError("expected floating-point, found `" ++ @typeName(@TypeOf(value)) ++ "`");
                };

                return try serializeFloat(self.context, value);
            }

            /// Serializes an integer value.
            pub fn serializeInt(self: Self, value: anytype) Error!Ok {
                if (comptime !std.meta.trait.isIntegral(@TypeOf(value))) {
                    @compileError("expected integer, found `" ++ @typeName(@TypeOf(value)) ++ "`");
                }

                return try serializeInt(self.context, value);
            }

            /// Starts the serialization process for a map.
            pub fn serializeMap(self: Self, length: ?usize) Error!MapSerialize {
                return try serializeMap(self.context, length);
            }

            /// Serializes a `null` value.
            pub fn serializeNull(self: Self) Error!Ok {
                return try serializeNull(self.context);
            }

            /// Starts the serialization process for a sequence.
            pub fn serializeSequence(self: Self, length: ?usize) Error!SequenceSerialize {
                return try serializeSequence(self.context, length);
            }

            /// Serializes the payload of an optional.
            pub fn serializeSome(self: Self, value: anytype) Error!Ok {
                return try serializeSome(self.context, value);
            }

            /// Serializes a string value.
            pub fn serializeString(self: Self, value: anytype) Error!Ok {
                if (comptime !std.meta.trait.isZigString(@TypeOf(value))) {
                    @compileError("expected string, found `" ++ @typeName(@TypeOf(value)) ++ "`");
                }

                return try serializeString(self.context, value);
            }

            /// Starts the serialization process for a struct.
            pub fn serializeStruct(self: Self, comptime name: []const u8, length: usize) Error!StructSerialize {
                return try serializeStruct(self.context, name, length);
            }

            /// Starts the serialization process for a tuple.
            pub fn serializeTuple(self: Self, length: ?usize) Error!TupleSerialize {
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
