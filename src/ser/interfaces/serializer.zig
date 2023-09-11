const std = @import("std");

const err = @import("../error.zig");
const default_st = @import("../tuples.zig").st;

/// A `Serializer` serializes values from Getty's data model into a data format.
pub fn Serializer(
    /// An implementing type.
    comptime Impl: type,
    /// The successful return type of the interface's `end` method.
    comptime T: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime E: type,
    /// An optional, user-defined serialization block or tuple.
    comptime user_sbt: anytype,
    /// An optional, serializer-defined serialization block or tuple.
    comptime serializer_sbt: anytype,
    /// An optional type that implements `getty.ser.Map`.
    comptime Map: ?type,
    /// An optional type that implements `getty.ser.Seq`.
    comptime Seq: ?type,
    /// An optional type that implements `getty.ser.Structure`.
    comptime Struct: ?type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        serializeBool: SerializeBoolFn(Impl, T, E) = null,
        serializeEnum: SerializeEnumFn(Impl, T, E) = null,
        serializeFloat: SerializeAnyFn(Impl, T, E) = null,
        serializeInt: SerializeAnyFn(Impl, T, E) = null,
        serializeMap: SerializeMapSeqFn(Impl, Map, E) = null,
        serializeNull: SerializeNothingFn(Impl, T, E) = null,
        serializeSeq: SerializeMapSeqFn(Impl, Seq, E) = null,
        serializeSome: SerializeAnyFn(Impl, T, E) = null,
        serializeString: SerializeAnyFn(Impl, T, E) = null,
        serializeStruct: SerializeStructFn(Impl, Struct, E) = null,
        serializeVoid: SerializeNothingFn(Impl, T, E) = null,
    },
) type {
    if (E != E || err.Error) {
        @compileError("error set must include `getty.ser.Error`");
    }

    return struct {
        /// An interface type.
        pub const @"getty.Serializer" = struct {
            impl: Impl,

            const Self = @This();

            /// Successful return type.
            pub const Ok = T;

            /// Error set used upon failure.
            pub const Err = E;

            /// User-defined Serialization Tuple.
            pub const user_st = blk: {
                // Process null.
                if (@TypeOf(user_sbt) == @TypeOf(null)) {
                    break :blk .{};
                }

                // Process SB.
                if (@TypeOf(user_sbt) == type) {
                    // If an attribute map exists, but no attributes are
                    // specified, ignore the SB.
                    if (@hasDecl(user_sbt, "attributes")) {
                        if (std.meta.fields(@TypeOf(user_sbt.attributes)).len == 0) {
                            break :blk .{};
                        }
                    }

                    break :blk .{user_sbt};
                }

                // Process ST.
                if (@TypeOf(user_sbt) == @TypeOf(default_st)) {
                    break :blk .{};
                }

                break :blk user_sbt;
            };

            /// Serializer-defined Serialization Tuple.
            pub const serializer_st = blk: {
                // Process null.
                if (@TypeOf(serializer_sbt) == @TypeOf(null)) {
                    break :blk .{};
                }

                // Process SB.
                if (@TypeOf(serializer_sbt) == type) {
                    // If an attribute map exists, but no attributes are
                    // specified, ignore the SB.
                    if (@hasDecl(serializer_sbt, "attributes")) {
                        if (std.meta.fields(@TypeOf(serializer_sbt.attributes)).len == 0) {
                            break :blk .{};
                        }
                    }

                    break :blk .{serializer_sbt};
                }

                // Process ST.
                if (@TypeOf(serializer_sbt) == @TypeOf(default_st)) {
                    break :blk .{};
                }

                break :blk serializer_sbt;
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
                const U = @TypeOf(user_st);
                const S = @TypeOf(serializer_st);
                const Empty = @TypeOf(.{});

                if (U == Empty and S == Empty) {
                    // Both tuples are empty or the default ST.
                    break :blk default_st;
                } else if (U != Empty and S == Empty) {
                    // User tuple is custom but serializer tuple is empty or the default ST.
                    break :blk user_st ++ default_st;
                } else if (S != Empty and U == Empty) {
                    // Serializer tuple is custom but user tuple is empty or the default ST.
                    break :blk serializer_st ++ default_st;
                } else {
                    // Both tuples are custom.
                    break :blk user_st ++ serializer_st ++ default_st;
                }
            };

            /// Serializes a Getty Boolean value.
            pub fn serializeBool(self: Self, value: bool) E!T {
                if (methods.serializeBool) |func| {
                    return try func(self.impl, value);
                }

                @compileError("serializeBool is not implemented by type: " ++ @typeName(Impl));
            }

            // Serializes a Getty Enum value.
            pub fn serializeEnum(self: Self, index: anytype, name: []const u8) E!T {
                if (methods.serializeEnum) |func| {
                    switch (@typeInfo(@TypeOf(index))) {
                        .Int, .ComptimeInt => return try func(self.impl, index, name),
                        else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(index))),
                    }
                }

                @compileError("serializeEnum is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Float value.
            pub fn serializeFloat(self: Self, value: anytype) E!T {
                if (methods.serializeFloat) |func| {
                    switch (@typeInfo(@TypeOf(value))) {
                        .Float, .ComptimeFloat => return try func(self.impl, value),
                        else => @compileError("expected float, found: " ++ @typeName(@TypeOf(value))),
                    }
                }

                @compileError("serializeFloat is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Integer value.
            pub fn serializeInt(self: Self, value: anytype) E!T {
                if (methods.serializeInt) |func| {
                    switch (@typeInfo(@TypeOf(value))) {
                        .Int, .ComptimeInt => return try func(self.impl, value),
                        else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(value))),
                    }
                }

                @compileError("serializeInt is not implemented by type: " ++ @typeName(Impl));
            }

            /// Begins the serialization process for a Getty Map value.
            pub fn serializeMap(self: Self, length: ?usize) blk: {
                if (Map) |M| {
                    break :blk E!M;
                }

                // If Map is null, then this function will raise a compile
                // error, so it doesn't really matter what the return type will
                // be. However, we use E!Impl specifically for its clean error
                // messages.
                break :blk E!Impl;
            } {
                if (Map == null) {
                    @compileError("serializeMap requires getty.ser.Map to be non-null");
                }

                if (methods.serializeMap) |func| {
                    return try func(self.impl, length);
                }

                @compileError("serializeMap is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Null value.
            pub fn serializeNull(self: Self) E!T {
                if (methods.serializeNull) |func| {
                    return try func(self.impl);
                }

                @compileError("serializeNull is not implemented by type: " ++ @typeName(Impl));
            }

            /// Begins the serialization process for a Getty Sequence value.
            pub fn serializeSeq(self: Self, length: ?usize) blk: {
                if (Seq) |S| {
                    break :blk E!S;
                }

                // If Seq is null, then this function will raise a compile
                // error, so it doesn't really matter what the return type will
                // be. However, we use E!Impl specifically for its clean error
                // messages.
                break :blk E!Impl;
            } {
                if (Seq == null) {
                    @compileError("serializeSeq requires getty.ser.Seq to be non-null");
                }

                if (methods.serializeSeq) |func| {
                    return try func(self.impl, length);
                }

                @compileError("serializeSeq is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Optional value.
            pub fn serializeSome(self: Self, value: anytype) E!T {
                if (methods.serializeSome) |func| {
                    return try func(self.impl, value);
                }

                @compileError("serializeSome is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty String value.
            pub fn serializeString(self: Self, value: anytype) E!T {
                if (methods.serializeString) |func| {
                    if (comptime !std.meta.trait.isZigString(@TypeOf(value))) {
                        @compileError("expected string, found: " ++ @typeName(@TypeOf(value)));
                    }

                    return try func(self.impl, value);
                }

                @compileError("serializeString is not implemented by type: " ++ @typeName(Impl));
            }

            /// Begins the serialization process for a Getty Struct value.
            pub fn serializeStruct(self: Self, comptime name: []const u8, length: usize) blk: {
                if (Struct) |S| {
                    break :blk E!S;
                }

                // If Struct is null, then this function will raise a compile
                // error, so it doesn't really matter what the return type will
                // be. However, we use E!Impl specifically for its clean error
                // messages.
                break :blk E!Impl;
            } {
                if (Struct == null) {
                    @compileError("serializeStruct requires getty.ser.Structure to be non-null");
                }

                if (methods.serializeStruct) |func| {
                    return try func(self.impl, name, length);
                }

                @compileError("serializeStruct is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Void value.
            pub fn serializeVoid(self: Self) E!T {
                if (methods.serializeVoid) |func| {
                    return try func(self.impl);
                }

                @compileError("serializeVoid is not implemented by type: " ++ @typeName(Impl));
            }
        };

        /// Returns an interface value.
        pub fn serializer(impl: Impl) @"getty.Serializer" {
            return .{ .impl = impl };
        }
    };
}

fn SerializeAnyFn(comptime Impl: type, comptime T: type, comptime E: type) type {
    return ?fn (impl: Impl, value: anytype) E!T;
}

fn SerializeBoolFn(comptime Impl: type, comptime T: type, comptime E: type) type {
    return ?fn (impl: Impl, value: bool) E!T;
}

fn SerializeEnumFn(comptime Impl: type, comptime T: type, comptime E: type) type {
    return ?fn (impl: Impl, index: anytype, name: []const u8) E!T;
}

fn SerializeMapSeqFn(comptime Impl: type, comptime MapSeq: ?type, comptime E: type) type {
    return ?fn (impl: Impl, length: ?usize) blk: {
        if (MapSeq) |T| {
            break :blk E!T;
        }

        // If MapSeq is null, then this function will raise a compile error, so
        // it doesn't really matter what the return type will be. However, we
        // use E!Impl specifically for its clean error messages.
        break :blk E!Impl;
    };
}

fn SerializeNothingFn(comptime Impl: type, comptime T: type, comptime E: type) type {
    return ?fn (impl: Impl) E!T;
}

fn SerializeStructFn(comptime Impl: type, comptime Struct: ?type, comptime E: type) type {
    return ?fn (impl: Impl, comptime name: []const u8, length: usize) blk: {
        if (Struct) |T| {
            break :blk E!T;
        }

        // If Struct is null, then this function will raise a compile error, so
        // it doesn't really matter what the return type will be. However, we
        // use E!Impl specifically for its clean error messages.
        break :blk E!Impl;
    };
}
