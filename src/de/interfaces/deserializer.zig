const std = @import("std");

const de = @import("../../de.zig");

/// Deserializer interface.
///
/// Deserializers are responsible for the following conversion:
///
///              Getty Data Model
///
///                     ▲          <-------
///                     |                 |
///                                       |
///                Data Format            |
///                                       |
///                                       |
///                                       |
///                                       |
///
///                               `getty.Deserializer`
///
/// Notice how Zig data is not a part of this conversion. Deserializers only
/// convert into values that fall under Getty's data model. In other words, a
/// Getty deserializer specifies how to convert a JSON map into Getty map, not
/// how to convert a JSON map into a `struct { x: i32 }`.
///
/// Parameters
/// ==========
///
///     Context
///     -------
///
///         This is the type that implements `getty.Deserializer` (or a pointer to it).
///
///     E
///     -
///
///         The error set used by all of `getty.Deserializer`'s methods upon failure.
///
///     user_dbt
///     --------
///
///         A Deserialization Block or Tuple.
///
///         This parameter is intended for users of a deserializer, enabling
///         them to use their own custom deserialization logic.
///
///     deserializer_dbt
///     ----------------
///
///         A Deserialization Block or Tuple.
///
///         This parameter is intended for deserializers, enabling them to use
///         their own custom deserialization logic.
///
///     deserializeXXX
///     --------------
///
///         Methods required by `getty.Deserializer` to carry out
///         deserialization.
///
///         Each method converts data from an input data format into Getty's
///         data model. This is done by calling a method on the `visitor`
///         parameter, which is a `getty.de.Visitor` interface value. For
///         example, the `deserializeInt` method of a typical JSON deserializer
///         would parse an integer from the input data and then map it to
///         Getty's data model by passing the integer value to the visitor
///         parameter's `visitInt` method. The visitor would then produce a Zig
///         integer or whatever other value it wants from the Getty integer on
///         its own.
pub fn Deserializer(
    comptime Context: type,
    comptime E: type,
    comptime user_dbt: anytype,
    comptime deserializer_dbt: anytype,
    comptime impls: struct {
        const T = ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, visitor: anytype) E!@TypeOf(visitor).Value {
                unreachable;
            }
        }.f);

        deserializeBool: T = null,
        deserializeEnum: T = null,
        deserializeFloat: T = null,
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
    comptime {
        de.concepts.@"getty.de.dbt"(user_dbt);
        de.concepts.@"getty.de.dbt"(deserializer_dbt);

        //TODO: Add concept for Error (blocked by concepts library).
    }

    return struct {
        pub const @"getty.Deserializer" = struct {
            context: Context,

            const Self = @This();

            /// Error set used upon failure.
            pub const Error = E;

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
                        if (user_dbt.attributes.len == 0) {
                            break :blk .{};
                        }
                    }

                    break :blk .{user_dbt};
                }

                // Process ST.
                if (@TypeOf(user_dbt) == @TypeOf(de.default_dt)) {
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
                        if (deserializer_dbt.attributes.len == 0) {
                            break :blk .{};
                        }
                    }

                    break :blk .{deserializer_dbt};
                }

                // Process ST.
                if (@TypeOf(deserializer_dbt) == @TypeOf(de.default_dt)) {
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
                    break :blk de.default_dt;
                } else if (U != Empty and D == Empty) {
                    // User tuple is custom but deserializer tuple is empty or the default DT.
                    break :blk user_dt ++ de.default_dt;
                } else if (D != Empty and U == Empty) {
                    // Deserializer tuple is custom but user tuple is empty or the default DT.
                    break :blk deserializer_dt ++ de.default_dt;
                } else {
                    // Both tuples are custom.
                    break :blk user_dt ++ deserializer_dt ++ de.default_dt;
                }
            };

            /// Deserializes a deserializer's input data into a Getty Boolean.
            pub fn deserializeBool(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeBool) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeBool is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Enum.
            pub fn deserializeEnum(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeEnum) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeEnum is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Float.
            pub fn deserializeFloat(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeFloat) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeFloat is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Integer.
            pub fn deserializeInt(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeInt) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeInt is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Map.
            pub fn deserializeMap(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeMap) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeMap is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Optional.
            pub fn deserializeOptional(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeOptional) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeOptional is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Sequence.
            pub fn deserializeSeq(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeSeq) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeSeq is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty String.
            pub fn deserializeString(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeString) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeString is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Struct.
            pub fn deserializeStruct(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeStruct) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeStruct is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Union.
            pub fn deserializeUnion(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeUnion) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeUnion is not implemented by type: " ++ @typeName(Context));
            }

            /// Deserializes a deserializer's input data into a Getty Void.
            pub fn deserializeVoid(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                if (impls.deserializeVoid) |f| {
                    return try f(self.context, allocator, visitor);
                }

                @compileError("deserializeVoid is not implemented by type: " ++ @typeName(Context));
            }
        };

        pub fn deserializer(self: Context) @"getty.Deserializer" {
            return .{ .context = self };
        }

        fn Return(comptime Visitor: type) type {
            comptime de.concepts.@"getty.de.Visitor"(Visitor);

            return E!Visitor.Value;
        }
    };
}
