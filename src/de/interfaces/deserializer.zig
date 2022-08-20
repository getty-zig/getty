const getty = @import("../../lib.zig");
const std = @import("std");

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
///     Error
///     -----
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
///     de_dbt
///     -------
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
    comptime de_dbt: anytype,
    comptime deserializeBoolFn: Fn(Context, E),
    comptime deserializeEnumFn: Fn(Context, E),
    comptime deserializeFloatFn: Fn(Context, E),
    comptime deserializeIntFn: Fn(Context, E),
    comptime deserializeMapFn: Fn(Context, E),
    comptime deserializeOptionalFn: Fn(Context, E),
    comptime deserializeSeqFn: Fn(Context, E),
    comptime deserializeStringFn: Fn(Context, E),
    comptime deserializeStructFn: Fn(Context, E),
    comptime deserializeUnionFn: Fn(Context, E),
    comptime deserializeVoidFn: Fn(Context, E),
) type {
    comptime {
        getty.concepts.@"getty.de.dbt"(user_dbt);
        getty.concepts.@"getty.de.dbt"(de_dbt);

        //TODO: Add concept for Error (blocked by concepts library).
    }

    return struct {
        pub const @"getty.Deserializer" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub const dt = blk: {
                const user_dt = if (@TypeOf(user_dbt) == type) .{user_dbt} else user_dbt;
                const de_dt = if (@TypeOf(de_dbt) == type) .{de_dbt} else de_dbt;
                const default = getty.default_dt;

                const U = @TypeOf(user_dt);
                const D = @TypeOf(de_dt);
                const Default = @TypeOf(default);

                if (U == Default and D == Default) {
                    break :blk default;
                } else if (U != Default and D == Default) {
                    break :blk user_dt ++ default;
                } else if (U == Default and D != Default) {
                    break :blk de_dt ++ default;
                } else {
                    break :blk user_dt ++ de_dt ++ default;
                }
            };

            pub fn deserializeBool(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeBoolFn(self.context, allocator, visitor);
            }

            pub fn deserializeEnum(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeEnumFn(self.context, allocator, visitor);
            }

            pub fn deserializeFloat(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeFloatFn(self.context, allocator, visitor);
            }

            pub fn deserializeInt(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeIntFn(self.context, allocator, visitor);
            }

            pub fn deserializeMap(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeMapFn(self.context, allocator, visitor);
            }

            pub fn deserializeOptional(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeOptionalFn(self.context, allocator, visitor);
            }

            pub fn deserializeSeq(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeSeqFn(self.context, allocator, visitor);
            }

            pub fn deserializeString(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeStringFn(self.context, allocator, visitor);
            }

            pub fn deserializeStruct(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeStructFn(self.context, allocator, visitor);
            }

            pub fn deserializeUnion(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeUnionFn(self.context, allocator, visitor);
            }

            pub fn deserializeVoid(self: Self, allocator: ?std.mem.Allocator, visitor: anytype) Return(@TypeOf(visitor)) {
                return try deserializeVoidFn(self.context, allocator, visitor);
            }
        };

        pub fn deserializer(self: Context) @"getty.Deserializer" {
            return .{ .context = self };
        }

        fn Return(comptime Visitor: type) type {
            comptime getty.concepts.@"getty.de.Visitor"(Visitor);

            return E!Visitor.Value;
        }
    };
}

fn Fn(comptime Context: type, comptime Error: type) type {
    const S = struct {
        fn f(_: Context, _: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
            unreachable;
        }
    };

    return @TypeOf(S.f);
}
