//! Serializer interface.
//!
//! Serializers define how to convert from Getty's data model into a data
//! format.

const concepts = @import("concepts");
const getty = @import("../../lib.zig");
const std = @import("std");

/// Returns an anonymously namespaced interface function for serializers.
pub fn Serializer(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime user_with: anytype,
    comptime ser_with: anytype,
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
        getty.concepts.@"getty.ser.with"(user_with);
        getty.concepts.@"getty.ser.with"(ser_with);

        //TODO: Add concept for Error (blocked by concepts library).
    }

    return struct {
        pub const @"getty.Serializer" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = Ok;

            /// The error set used upon failure.
            pub const Error = Error;

            pub const with = blk: {
                const uwith = if (@TypeOf(user_with) == type) .{user_with} else user_with;
                const swith = if (@TypeOf(ser_with) == type) .{ser_with} else ser_with;
                const U = @TypeOf(uwith);
                const S = @TypeOf(swith);
                const Default = @TypeOf(getty.swt);

                if (U == Default and S == Default) {
                    break :blk getty.swt;
                } else if (U != Default and S == Default) {
                    break :blk uwith ++ getty.swt;
                } else if (U == Default and S != Default) {
                    break :blk swith ++ getty.swt;
                } else {
                    break :blk uwith ++ swith ++ getty.swt;
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
