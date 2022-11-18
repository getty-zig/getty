const std = @import("std");

const ser = @import("../../ser.zig");

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
///     O
///     -
///
///         The successful return type for a majority of `getty.Serializer`'s methods.
///
///     E
///     -
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
///     serializer_sbt
///     --------------
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
///     serializeXXX
///     ------------
///
///         Methods required by `getty.Serializer` to carry out serialization.
///
///         Most of the methods are one and done (i.e., you call them once and
///         in return you get a fully serialized value). However, some methods
///         (specifically, the ones for compound data types like `serializeMap`
///         and `serializeSeq`), only begin the serialization process. The
///         caller must then continue serialization by using the returned
///         `getty.ser.Map|Seq|Struct` implementation.
pub fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime user_sbt: anytype,
    comptime serializer_sbt: anytype,
    comptime Map: type,
    comptime Seq: type,
    comptime Struct: type,
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
        serializeEnum: ?fn (Context, anytype) E!O = null,
        serializeFloat: ?fn (Context, anytype) E!O = null,
        serializeInt: ?fn (Context, anytype) E!O = null,
        serializeMap: ?fn (Context, ?usize) E!Map = null,
        serializeNull: ?fn (Context) E!O = null,
        serializeSeq: ?fn (Context, ?usize) E!Seq = null,
        serializeSome: ?fn (Context, anytype) E!O = null,
        serializeString: ?fn (Context, anytype) E!O = null,
        serializeStruct: ?@TypeOf(struct {
            fn f(self: Context, comptime name: []const u8, length: usize) E!Struct {
                _ = self;
                _ = name;
                _ = length;

                unreachable;
            }
        }.f) = null,
        serializeVoid: ?fn (Context) E!O = null,
    },
) type {
    comptime {
        ser.concepts.@"getty.ser.sbt"(user_sbt);
        ser.concepts.@"getty.ser.sbt"(serializer_sbt);

        //TODO: Add concept for Error (blocked by concepts library).
    }

    return struct {
        pub const @"getty.Serializer" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// Error set used upon failure.
            pub const Error = E;

            /// User-defined Serialization Tuple.
            pub const user_st = blk: {
                const user_tuple = inner_blk: {
                    if (@TypeOf(user_sbt) != type) {
                        break :inner_blk user_sbt;
                    }

                    // If an attribute map exists, but no attributes are
                    // specified, ignore the SB.
                    if (@hasDecl(user_sbt, "attributes")) {
                        if (user_sbt.attributes.len == 0) {
                            break :inner_blk .{};
                        }
                    }

                    break :inner_blk .{user_sbt};
                };

                if (@TypeOf(user_tuple) == @TypeOf(ser.default_st)) {
                    break :blk .{};
                }

                break :blk user_tuple;
            };

            /// Serializer-defined Serialization Tuple.
            pub const serializer_st = blk: {
                const serializer_tuple = inner_blk: {
                    if (@TypeOf(serializer_sbt) != type) {
                        break :inner_blk serializer_sbt;
                    }

                    // If an attribute map exists, but no attributes are
                    // specified, ignore the SB.
                    if (@hasDecl(serializer_sbt, "attributes")) {
                        if (serializer_sbt.attributes.len == 0) {
                            break :inner_blk .{};
                        }
                    }

                    break :inner_blk .{serializer_sbt};
                };

                if (@TypeOf(serializer_tuple) == @TypeOf(ser.default_st)) {
                    break :blk .{};
                } else {
                    break :blk serializer_tuple;
                }
            };

            /// Aggregate Serialization Tuple.
            ///
            /// The Aggregate ST combines the user-, serializer-, and Getty's
            /// default Serialization Tuples into one.
            ///
            /// The priority of each ST is shown below (from highest to lowest):
            ///
            ///   1. User-defined ST.
            ///   2. Serializer-defined ST.
            ///   3. Getty's default ST.
            pub const st = blk: {
                const user_tuple = if (@TypeOf(user_sbt) == type) .{user_sbt} else user_sbt;
                const serializer_tuple = if (@TypeOf(serializer_sbt) == type) .{serializer_sbt} else serializer_sbt;
                const default = ser.default_st;

                const U = @TypeOf(user_tuple);
                const S = @TypeOf(serializer_tuple);
                const Default = @TypeOf(default);
                const Empty = @TypeOf(.{});

                if ((U == Default or U == Empty) and (S == Default or S == Empty)) {
                    // Both tuples are empty or the default ST.
                    break :blk default;
                } else if (U != Default and U != Empty and (S == Default or S == Empty)) {
                    // User tuple is custom but serializer tuple is empty or the default ST.
                    break :blk user_tuple ++ default;
                } else if (S != Default and S != Empty and (U == Default or U == Empty)) {
                    // Serailizer tuple is custom but user tuple is empty or the default ST.
                    break :blk serializer_tuple ++ default;
                } else {
                    // Both tuples are custom.
                    break :blk user_tuple ++ serializer_tuple ++ default;
                }
            };

            /// Serializes a Getty Boolean value.
            pub fn serializeBool(self: Self, value: bool) Error!Ok {
                if (methods.serializeBool) |f| {
                    return try f(self.context, value);
                }

                @compileError("serializeBool is not implemented by type: " ++ @typeName(Context));
            }

            // Serializes a Getty Enum value.
            pub fn serializeEnum(self: Self, value: anytype) Error!Ok {
                if (methods.serializeEnum) |f| {
                    switch (@typeInfo(@TypeOf(value))) {
                        .Enum, .EnumLiteral => return try f(self.context, value),
                        else => @compileError("expected enum, found: " ++ @typeName(@TypeOf(value))),
                    }
                }

                @compileError("serializeEnum is not implemented by type: " ++ @typeName(Context));
            }

            /// Serializes a Getty Float value.
            pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
                if (methods.serializeFloat) |f| {
                    switch (@typeInfo(@TypeOf(value))) {
                        .Float, .ComptimeFloat => return try f(self.context, value),
                        else => @compileError("expected float, found: " ++ @typeName(@TypeOf(value))),
                    }
                }

                @compileError("serializeFloat is not implemented by type: " ++ @typeName(Context));
            }

            /// Serializes a Getty Integer value.
            pub fn serializeInt(self: Self, value: anytype) Error!Ok {
                if (methods.serializeInt) |f| {
                    switch (@typeInfo(@TypeOf(value))) {
                        .Int, .ComptimeInt => return try f(self.context, value),
                        else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(value))),
                    }
                }

                @compileError("serializeInt is not implemented by type: " ++ @typeName(Context));
            }

            /// Begins the serialization process for a Getty Map value.
            pub fn serializeMap(self: Self, length: ?usize) Error!Map {
                if (methods.serializeMap) |f| {
                    return try f(self.context, length);
                }

                @compileError("serializeMap is not implemented by type: " ++ @typeName(Context));
            }

            /// Serializes a Getty Null value.
            pub fn serializeNull(self: Self) Error!Ok {
                if (methods.serializeNull) |f| {
                    return try f(self.context);
                }

                @compileError("serializeNull is not implemented by type: " ++ @typeName(Context));
            }

            /// Begins the serialization process for a Getty Sequence value.
            pub fn serializeSeq(self: Self, length: ?usize) Error!Seq {
                if (methods.serializeSeq) |f| {
                    return try f(self.context, length);
                }

                @compileError("serializeSeq is not implemented by type: " ++ @typeName(Context));
            }

            /// Serializes a Getty Optional value.
            pub fn serializeSome(self: Self, value: anytype) Error!Ok {
                if (methods.serializeSome) |f| {
                    return try f(self.context, value);
                }

                @compileError("serializeSome is not implemented by type: " ++ @typeName(Context));
            }

            /// Serializes a Getty String value.
            pub fn serializeString(self: Self, value: anytype) Error!Ok {
                if (methods.serializeString) |f| {
                    if (comptime !std.meta.trait.isZigString(@TypeOf(value))) {
                        @compileError("expected string, found: " ++ @typeName(@TypeOf(value)));
                    }

                    return try f(self.context, value);
                }

                @compileError("serializeString is not implemented by type: " ++ @typeName(Context));
            }

            /// Begins the serialization process for a Getty Struct value.
            pub fn serializeStruct(self: Self, comptime name: []const u8, length: usize) Error!Struct {
                if (methods.serializeStruct) |f| {
                    return try f(self.context, name, length);
                }

                @compileError("serializeStruct is not implemented by type: " ++ @typeName(Context));
            }

            /// Serializes a Getty Void value.
            pub fn serializeVoid(self: Self) Error!Ok {
                if (methods.serializeVoid) |f| {
                    return try f(self.context);
                }

                @compileError("serializeVoid is not implemented by type: " ++ @typeName(Context));
            }
        };

        pub fn serializer(self: Context) @"getty.Serializer" {
            return .{ .context = self };
        }
    };
}
