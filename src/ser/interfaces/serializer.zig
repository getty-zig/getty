const std = @import("std");

const err = @import("../error.zig");
const tuples = @import("../tuples.zig");

/// A `Serializer` serializes values from Getty's data model into a data format.
pub fn Serializer(
    /// A namespace that owns the method implementations passed to the `methods` parameter.
    comptime Context: type,
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
    /// A namespace containing the methods that implementations of `Serializer` can implement.
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
        serializeEnum: ?fn (Context, anytype, []const u8) E!O = null,
        serializeFloat: ?fn (Context, anytype) E!O = null,
        serializeInt: ?fn (Context, anytype) E!O = null,
        serializeMap: blk: {
            if (Map) |T| {
                break :blk ?fn (Context, ?usize) E!T;
            }

            // If Map is null, serializeMap will raise a compile error. The
            // following type is a sort of catch-all type that can store any
            // value. It doesn't matter what the value is though since the
            // compiler will error out as I've mentioned.
            break :blk E!?*const anyopaque;
        } = null,
        serializeNull: ?fn (Context) E!O = null,
        serializeSeq: blk: {
            if (Seq) |T| {
                break :blk ?fn (Context, ?usize) E!T;
            }

            // If Seq is null, serializeSeq will raise a compile error. The
            // following type is a sort of catch-all type that can store any
            // value. It doesn't matter what the value is though since the
            // compiler will error out as I've mentioned.
            break :blk E!?*const anyopaque;
        } = null,
        serializeSome: ?fn (Context, anytype) E!O = null,
        serializeString: ?fn (Context, anytype) E!O = null,
        serializeStruct: blk: {
            if (Structure) |T| {
                break :blk ?fn (Context, comptime []const u8, usize) E!T;
            }

            // If Structure is null, serializeStruct will raise a compile
            // error. The following type is a sort of catch-all type that can
            // store any value. It doesn't matter what the value is though
            // since the compiler will error out as I've mentioned.
            break :blk E!?*const anyopaque;
        } = null,
        serializeVoid: ?fn (Context) E!O = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.Serializer" = struct {
            context: Context,

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
                if (@TypeOf(user_sbt) == @TypeOf(tuples.default)) {
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
                if (@TypeOf(serializer_sbt) == @TypeOf(tuples.default)) {
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
                    break :blk tuples.default;
                } else if (U != Empty and S == Empty) {
                    // User tuple is custom but serializer tuple is empty or the default ST.
                    break :blk user_st ++ tuples.default;
                } else if (S != Empty and U == Empty) {
                    // Serializer tuple is custom but user tuple is empty or the default ST.
                    break :blk serializer_st ++ tuples.default;
                } else {
                    // Both tuples are custom.
                    break :blk user_st ++ serializer_st ++ tuples.default;
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
            pub fn serializeEnum(self: Self, index: anytype, name: []const u8) Error!Ok {
                if (methods.serializeEnum) |f| {
                    switch (@typeInfo(@TypeOf(index))) {
                        .Int, .ComptimeInt => return try f(self.context, index, name),
                        else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(index))),
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
            pub fn serializeMap(self: Self, length: ?usize) blk: {
                if (Map) |T| {
                    break :blk Error!T;
                }

                // If Map is null, then this function will raise a compile
                // error, so it doesn't really matter what the return type will
                // be. However, we use Error!Context specifically for its clean
                // error messages. It'll result in errors such as "no field or
                // member function named 'map' in 'ser.TestSerializer'
                break :blk Error!Context;
            } {
                if (Map == null) {
                    @compileError("serializeMap requires getty.ser.Map to be non-null");
                }

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
            pub fn serializeSeq(self: Self, length: ?usize) blk: {
                if (Seq) |T| {
                    break :blk Error!T;
                }

                // If Seq is null, then this function will raise a compile
                // error, so it doesn't really matter what the return type will
                // be. However, we use Error!Context specifically for its clean
                // error messages. It'll result in errors such as "no field or
                // member function named 'seq' in 'ser.TestSerializer'
                break :blk Error!Context;
            } {
                if (Seq == null) {
                    @compileError("serializeSeq requires getty.ser.Seq to be non-null");
                }

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
            pub fn serializeStruct(self: Self, comptime name: []const u8, length: usize) blk: {
                if (Structure) |T| {
                    break :blk Error!T;
                }

                // If Structure is null, then this function will raise a
                // compile error, so it doesn't really matter what the return
                // type will be. However, we use Error!Context specifically for
                // its clean error messages. It'll result in errors such as
                // "no field or member function named 'structure' in 'ser.TestSerializer'
                break :blk Error!Context;
            } {
                if (Structure == null) {
                    @compileError("serializeStruct requires getty.ser.Structure to be non-null");
                }

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

        /// Returns an interface value.
        pub fn serializer(self: Context) @"getty.Serializer" {
            return .{ .context = self };
        }
    };
}
