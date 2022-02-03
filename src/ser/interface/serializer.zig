//! Serializer interface.
//!
//! Serializers define how to convert from Getty's data model into a data
//! format.

const std = @import("std");

const concepts = @import("concepts");
const getty = @import("../../lib.zig");

/// Returns an anonymously namespaced interface function for serializers.
pub fn Serializer(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime with: ?type,
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
    comptime serializeSequence: fn (Context, ?usize) Error!Seq,
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
        if (with) |w| {
            getty.concepts.@"getty.with"(w);
        }

        // TODO: Add concept for Error (blocked by concepts library).
    }

    return struct {
        pub const @"getty.Serializer" = struct {
            const Self = @This();

            context: Context,

            /// Successful return type.
            pub const Ok = Ok;

            /// The error set used upon failure.
            pub const Error = Error;

            /// TODO
            pub const with = with;

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
            pub fn serializeSequence(self: Self, length: ?usize) Error!Seq {
                return try serializeSequence(self.context, length);
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
