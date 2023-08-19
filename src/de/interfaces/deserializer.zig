const std = @import("std");

const default_dt = @import("../tuples.zig").dt;
const err = @import("../error.zig");

/// A `Deserializer` deserializes values from a data format into Getty's data model.
pub fn Deserializer(
    /// An implementing type.
    comptime Impl: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// An optional, user-defined deserialization block or tuple.
    comptime user_dbt: anytype,
    /// An optional, deserializer-defined deserialization block or tuple.
    comptime deserializer_dbt: anytype,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        const T = ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, visitor: anytype) E!@TypeOf(visitor).Value {
                unreachable;
            }
        }.f);

        deserializeAny: T = null,
        deserializeBool: T = null,
        deserializeEnum: T = null,
        deserializeFloat: T = null,
        deserializeIgnored: T = null,
        deserializeInt: T = null,
        deserializeMap: T = null,
        deserializeOptional: T = null,
        deserializeSeq: T = null,
        deserializeString: T = null,
        deserializeStruct: T = null,
        deserializeUnion: T = null,
        deserializeVoid: T = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.Deserializer" = struct {
            impl: Impl,

            const Self = @This();

            /// Error set used upon failure.
            pub const Error = blk: {
                if (E != E || err.Error) {
                    @compileError("error set must include `getty.de.Error`");
                }

                break :blk E;
            };

            /// User-defined Deserialization Tuple.
            pub const user_dt = blk: {
                // Process null.
                if (@TypeOf(user_dbt) == @TypeOf(null)) {
                    break :blk .{};
                }

                // Process DB.
                if (@TypeOf(user_dbt) == type) {
                    // If an attribute map exists, but no attributes are
                    // specified, ignore the DB.
                    if (@hasDecl(user_dbt, "attributes")) {
                        if (std.meta.fields(@TypeOf(user_dbt.attributes)).len == 0) {
                            break :blk .{};
                        }
                    }

                    break :blk .{user_dbt};
                }

                // Process DT.
                if (@TypeOf(user_dbt) == @TypeOf(default_dt)) {
                    break :blk .{};
                }

                break :blk user_dbt;
            };

            /// Deserializer-defined Deserialization Tuple.
            pub const deserializer_dt = blk: {
                // Process null.
                if (@TypeOf(deserializer_dbt) == @TypeOf(null)) {
                    break :blk .{};
                }

                // Process DB.
                if (@TypeOf(deserializer_dbt) == type) {
                    // If an attribute map exists, but no attributes are
                    // specified, ignore the DB.
                    if (@hasDecl(deserializer_dbt, "attributes")) {
                        if (std.meta.fields(@TypeOf(deserializer_dbt.attributes)).len == 0) {
                            break :blk .{};
                        }
                    }

                    break :blk .{deserializer_dbt};
                }

                // Process DT.
                if (@TypeOf(deserializer_dbt) == @TypeOf(default_dt)) {
                    break :blk .{};
                }

                break :blk deserializer_dbt;
            };

            /// Aggregate Deserialization Tuple.
            ///
            /// The Aggregate DT combines the user-, deserializer-, and Getty's
            /// default Deserialization Tuples into one.
            ///
            /// The priority of each DT is shown below (from highest to lowest):
            ///
            ///   1. User-defined DT.
            ///   2. Deserializer-defined DT.
            ///   3. Getty's default DT.
            pub const dt = blk: {
                const U = @TypeOf(user_dt);
                const D = @TypeOf(deserializer_dt);
                const Empty = @TypeOf(.{});

                if (U == Empty and D == Empty) {
                    // Both tuples are empty or the default DT.
                    break :blk default_dt;
                } else if (U != Empty and D == Empty) {
                    // User tuple is custom but deserializer tuple is empty or the default DT.
                    break :blk user_dt ++ default_dt;
                } else if (D != Empty and U == Empty) {
                    // Deserializer tuple is custom but user tuple is empty or the default DT.
                    break :blk deserializer_dt ++ default_dt;
                } else {
                    // Both tuples are custom.
                    break :blk user_dt ++ deserializer_dt ++ default_dt;
                }
            };

            /// Deserializes a deserializer's input data into some Getty value.
            pub fn deserializeAny(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeAny) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeAny is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Boolean.
            pub fn deserializeBool(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeBool) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeBool is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Enum.
            pub fn deserializeEnum(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeEnum) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeEnum is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Float.
            pub fn deserializeFloat(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeFloat) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeFloat is not implemented by type: " ++ @typeName(Impl));
            }

            /// Hint that the type being deserialized into is expecting to
            /// deserialize a value whose type does not matter because it is
            /// ignored.
            pub fn deserializeIgnored(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeIgnored) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeIgnored is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Integer.
            pub fn deserializeInt(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeInt) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeInt is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Map.
            pub fn deserializeMap(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeMap) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeMap is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Optional.
            pub fn deserializeOptional(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeOptional) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeOptional is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Sequence.
            pub fn deserializeSeq(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeSeq) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeSeq is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty String.
            pub fn deserializeString(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeString) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeString is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Struct.
            pub fn deserializeStruct(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeStruct) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeStruct is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Union.
            pub fn deserializeUnion(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeUnion) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeUnion is not implemented by type: " ++ @typeName(Impl));
            }

            /// Deserializes a deserializer's input data into a Getty Void.
            pub fn deserializeVoid(self: Self, ally: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (methods.deserializeVoid) |f| {
                    return try f(self.impl, ally, visitor);
                }

                @compileError("deserializeVoid is not implemented by type: " ++ @typeName(Impl));
            }
        };

        /// Returns an interface value.
        pub fn deserializer(impl: Impl) @"getty.Deserializer" {
            return .{ .impl = impl };
        }
    };
}
