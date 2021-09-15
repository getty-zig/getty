//! Serializer interface.
//!
//! Serializers define how to convert from Getty's data model into a data
//! format.

const std = @import("std");

/// Returns an anonymously namespaced interface function for serializers.
pub fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime MapSerialize: type,
    comptime SequenceSerialize: type,
    comptime StructSerialize: type,
    comptime TupleSerialize: type,
    comptime boolFn: fn (Context, bool) E!O,
    comptime enumFn: fn (Context, anytype) E!O,
    comptime floatFn: fn (Context, anytype) E!O,
    comptime intFn: fn (Context, anytype) E!O,
    comptime mapFn: fn (Context, ?usize) E!MapSerialize,
    comptime nullFn: fn (Context) E!O,
    comptime sequenceFn: fn (Context, ?usize) E!SequenceSerialize,
    comptime stringFn: fn (Context, anytype) E!O,
    comptime structFn: fn (Context, comptime []const u8, usize) E!StructSerialize,
    comptime tupleFn: fn (Context, ?usize) E!TupleSerialize,
    comptime voidFn: fn (Context) E!O,
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        /// Successful return type.
        pub const Ok = O;

        /// The error set used upon failure.
        pub const Error = E;

        /// Serializes a `bool` value.
        pub fn serializeBool(self: Self, value: bool) Error!Ok {
            return try boolFn(self.context, value);
        }

        // Serializes an enum value.
        pub fn serializeEnum(self: Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value))) {
                .Enum, .EnumLiteral => {},
                else => @compileError("expected enum, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
            }

            return try enumFn(self.context, value);
        }

        /// Serializes a floating-point value.
        pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value))) {
                .Float, .ComptimeFloat => {},
                else => @compileError("expected float, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
            }

            return try floatFn(self.context, value);
        }

        /// Serializes an integer value.
        pub fn serializeInt(self: Self, value: anytype) Error!Ok {
            switch (@typeInfo(@TypeOf(value))) {
                .Int, .ComptimeInt => {},
                else => @compileError("expected int, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
            }

            return try intFn(self.context, value);
        }

        /// Starts the serialization process for a map.
        pub fn serializeMap(self: Self, length: ?usize) Error!MapSerialize {
            return try mapFn(self.context, length);
        }

        /// Serializes a `null` value.
        pub fn serializeNull(self: Self) Error!Ok {
            return try nullFn(self.context);
        }

        /// Starts the serialization process for a sequence.
        pub fn serializeSequence(self: Self, length: ?usize) Error!SequenceSerialize {
            return try sequenceFn(self.context, length);
        }

        /// Serializes a string value.
        pub fn serializeString(self: Self, value: anytype) Error!Ok {
            if (comptime !std.meta.trait.isZigString(@TypeOf(value))) {
                @compileError("expected string, found `" ++ @typeName(@TypeOf(value)) ++ "`");
            }

            return try stringFn(self.context, value);
        }

        /// Starts the serialization process for a struct.
        pub fn serializeStruct(self: Self, comptime name: []const u8, length: usize) Error!StructSerialize {
            return try structFn(self.context, name, length);
        }

        /// Starts the serialization process for a tuple.
        pub fn serializeTuple(self: Self, length: ?usize) Error!TupleSerialize {
            return try tupleFn(self.context, length);
        }

        /// Serializes a `void` value.
        pub fn serializeVoid(self: Self) Error!Ok {
            return try voidFn(self.context);
        }
    };

    return struct {
        pub fn serializer(self: Context) T {
            return .{ .context = self };
        }
    };
}
