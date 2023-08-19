const std = @import("std");

const err = @import("../error.zig");
const default_st = @import("../tuples.zig").st;

/// A `Serializer` serializes values from Getty's data model into a data format.
pub fn Serializer(
    /// An implementing type.
    comptime Impl: type,
    /// The successful return type of a `Serializer`'s `end` method.
    comptime O: type,
    /// The error set returned by a `Serializer`'s methods upon failure.
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
    comptime Structure: ?type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        serializeBool: ?fn (Impl, bool) E!O = null,
        serializeEnum: ?fn (Impl, anytype, []const u8) E!O = null,
        serializeFloat: ?fn (Impl, anytype) E!O = null,
        serializeInt: ?fn (Impl, anytype) E!O = null,
        serializeMap: blk: {
            if (Map) |T| {
                break :blk ?fn (Impl, ?usize) E!T;
            }

            // If Map is null, serializeMap will raise a compile error. The
            // following type is a sort of catch-all type that can store any
            // value. It doesn't matter what the value is though since the
            // compiler will error out as I've mentioned.
            break :blk E!?*const anyopaque;
        } = null,
        serializeNull: ?fn (Impl) E!O = null,
        serializeSeq: blk: {
            if (Seq) |T| {
                break :blk ?fn (Impl, ?usize) E!T;
            }

            // If Seq is null, serializeSeq will raise a compile error. The
            // following type is a sort of catch-all type that can store any
            // value. It doesn't matter what the value is though since the
            // compiler will error out as I've mentioned.
            break :blk E!?*const anyopaque;
        } = null,
        serializeSome: ?fn (Impl, anytype) E!O = null,
        serializeString: ?fn (Impl, anytype) E!O = null,
        serializeStruct: blk: {
            if (Structure) |T| {
                break :blk ?fn (Impl, comptime []const u8, usize) E!T;
            }

            // If Structure is null, serializeStruct will raise a compile
            // error. The following type is a sort of catch-all type that can
            // store any value. It doesn't matter what the value is though
            // since the compiler will error out as I've mentioned.
            break :blk E!?*const anyopaque;
        } = null,
        serializeVoid: ?fn (Impl) E!O = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.Serializer" = struct {
            impl: Impl,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// Error set used upon failure.
            pub const Error = blk: {
                if (E != E || err.Error) {
                    @compileError("error set must include `getty.ser.Error`");
                }

                break :blk E;
            };

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
            pub fn serializeBool(self: Self, value: bool) Error!Ok {
                if (methods.serializeBool) |f| {
                    return try f(self.impl, value);
                }

                @compileError("serializeBool is not implemented by type: " ++ @typeName(Impl));
            }

            // Serializes a Getty Enum value.
            pub fn serializeEnum(self: Self, index: anytype, name: []const u8) Error!Ok {
                if (methods.serializeEnum) |f| {
                    switch (@typeInfo(@TypeOf(index))) {
                        .Int, .ComptimeInt => return try f(self.impl, index, name),
                        else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(index))),
                    }
                }

                @compileError("serializeEnum is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Float value.
            pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
                if (methods.serializeFloat) |f| {
                    switch (@typeInfo(@TypeOf(value))) {
                        .Float, .ComptimeFloat => return try f(self.impl, value),
                        else => @compileError("expected float, found: " ++ @typeName(@TypeOf(value))),
                    }
                }

                @compileError("serializeFloat is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Integer value.
            pub fn serializeInt(self: Self, value: anytype) Error!Ok {
                if (methods.serializeInt) |f| {
                    switch (@typeInfo(@TypeOf(value))) {
                        .Int, .ComptimeInt => return try f(self.impl, value),
                        else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(value))),
                    }
                }

                @compileError("serializeInt is not implemented by type: " ++ @typeName(Impl));
            }

            /// Begins the serialization process for a Getty Map value.
            pub fn serializeMap(self: Self, length: ?usize) blk: {
                if (Map) |T| {
                    break :blk Error!T;
                }

                // If Map is null, then this function will raise a compile
                // error, so it doesn't really matter what the return type will
                // be. However, we use Error!Impl specifically for its clean
                // error messages. It'll result in errors such as "no field or
                // member function named 'map' in 'ser.TestSerializer'
                break :blk Error!Impl;
            } {
                if (Map == null) {
                    @compileError("serializeMap requires getty.ser.Map to be non-null");
                }

                if (methods.serializeMap) |f| {
                    return try f(self.impl, length);
                }

                @compileError("serializeMap is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Null value.
            pub fn serializeNull(self: Self) Error!Ok {
                if (methods.serializeNull) |f| {
                    return try f(self.impl);
                }

                @compileError("serializeNull is not implemented by type: " ++ @typeName(Impl));
            }

            /// Begins the serialization process for a Getty Sequence value.
            pub fn serializeSeq(self: Self, length: ?usize) blk: {
                if (Seq) |T| {
                    break :blk Error!T;
                }

                // If Seq is null, then this function will raise a compile
                // error, so it doesn't really matter what the return type will
                // be. However, we use Error!Impl specifically for its clean
                // error messages. It'll result in errors such as "no field or
                // member function named 'seq' in 'ser.TestSerializer'
                break :blk Error!Impl;
            } {
                if (Seq == null) {
                    @compileError("serializeSeq requires getty.ser.Seq to be non-null");
                }

                if (methods.serializeSeq) |f| {
                    return try f(self.impl, length);
                }

                @compileError("serializeSeq is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Optional value.
            pub fn serializeSome(self: Self, value: anytype) Error!Ok {
                if (methods.serializeSome) |f| {
                    return try f(self.impl, value);
                }

                @compileError("serializeSome is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty String value.
            pub fn serializeString(self: Self, value: anytype) Error!Ok {
                if (methods.serializeString) |f| {
                    if (comptime !std.meta.trait.isZigString(@TypeOf(value))) {
                        @compileError("expected string, found: " ++ @typeName(@TypeOf(value)));
                    }

                    return try f(self.impl, value);
                }

                @compileError("serializeString is not implemented by type: " ++ @typeName(Impl));
            }

            /// Begins the serialization process for a Getty Struct value.
            pub fn serializeStruct(self: Self, comptime name: []const u8, length: usize) blk: {
                if (Structure) |T| {
                    break :blk Error!T;
                }

                // If Structure is null, then this function will raise a
                // compile error, so it doesn't really matter what the return
                // type will be. However, we use Error!Impl specifically for
                // its clean error messages. It'll result in errors such as
                // "no field or member function named 'structure' in 'ser.TestSerializer'
                break :blk Error!Impl;
            } {
                if (Structure == null) {
                    @compileError("serializeStruct requires getty.ser.Structure to be non-null");
                }

                if (methods.serializeStruct) |f| {
                    return try f(self.impl, name, length);
                }

                @compileError("serializeStruct is not implemented by type: " ++ @typeName(Impl));
            }

            /// Serializes a Getty Void value.
            pub fn serializeVoid(self: Self) Error!Ok {
                if (methods.serializeVoid) |f| {
                    return try f(self.impl);
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
