//! Serialization framework.
//!
//! Visually, serialization within Getty can be represented like so:
//!
//!                  Zig data
//!
//!                     ↓          <------------------
//!                                                  |
//!              Getty Data Model                    |
//!                                                  |
//!                     ↓          <-------          |
//!                                       |          |
//!                Data Format            |          |
//!                                       |          |
//!                                       |
//!                                       |     `getty.Ser`
//!                                       |
//!
//!                               `getty.Serializer`
//!
//! # Data Model
//!
//! The Getty data model is the set of types supported by Getty. The types
//! within this set are purely conceptual; they aren't actual Zig types. For
//! example, there is no `i32` or `u64` in Getty's data model. Instead, they
//! are both considered to be the same type: integer.
//!
//! By maintaining a data model, Getty establishes a generic baseline from
//! which serializers can operate. This can often simplify the job of a
//! serializer significantly. For example, Zig considers `struct { x: i32 }`
//! and `struct { y: bool }` to be different types. However, in Getty they are
//! both considered to be the same type: struct. This means that if a
//! serializer supports struct (as defined by Getty) serialization, then by
//! definition it supports serialization for `struct { x: i32 }` values,
//! `struct { y: bool }` values, and values of any other struct type that is
//! composed of data types supported by Getty.
//!
//! # `Ser`s
//!
//! A `Ser` defines the conversion process between Zig types and Getty's data
//! model. For example, the `BoolSer` type, used internally by Getty, converts
//! `bool` values into the Boolean type, which is one of the types defined in
//! Getty's data model.
//!
//! # Serializers
//!
//! A serializer defines the conversion process between Getty's data model and
//! an output data format. For example, a JSON serializer would specify that
//! Getty strings should be serialized as `"<INSERT STRING HERE>"`.

const std = @import("std");

const ArrayListSer = @import("ser/impl/ser/array_list.zig");
const BoolSer = @import("ser/impl/ser/bool.zig");
const ErrorSer = @import("ser/impl/ser/error.zig");
const EnumSer = @import("ser/impl/ser/enum.zig");
const FloatSer = @import("ser/impl/ser/float.zig");
const IntSer = @import("ser/impl/ser/int.zig");
const OptionalSer = @import("ser/impl/ser/optional.zig");
const PointerSer = @import("ser/impl/ser/pointer.zig");
const NullSer = @import("ser/impl/ser/null.zig");
const LinkedListSer = @import("ser/impl/ser/linked_list.zig");
const SequenceSer = @import("ser/impl/ser/sequence.zig");
const StringSer = @import("ser/impl/ser/string.zig");
const HashMapSer = @import("ser/impl/ser/hash_map.zig");
const StructSer = @import("ser/impl/ser/struct.zig");
const TailQueueSer = @import("ser/impl/ser/tail_queue.zig");
const TupleSer = @import("ser/impl/ser/tuple.zig");
const UnionSer = @import("ser/impl/ser/union.zig");
const VectorSer = @import("ser/impl/ser/vector.zig");
const VoidSer = @import("ser/impl/ser/void.zig");

/// Serializer interface
pub usingnamespace @import("ser/interface/serializer.zig");

/// `Ser` interface
pub usingnamespace @import("ser/interface/ser.zig");

pub const ser = struct {
    /// Generic error set for `getty.Ser` implementations.
    pub const Error = std.mem.Allocator.Error || error{
        Unsupported,
    };

    pub usingnamespace @import("ser/interface/serialize/map.zig");
    pub usingnamespace @import("ser/interface/serialize/sequence.zig");
    pub usingnamespace @import("ser/interface/serialize/struct.zig");
    pub usingnamespace @import("ser/interface/serialize/tuple.zig");

    pub const concepts = struct {
        fn @"getty.Serializer"(comptime T: type) void {
            const err = "expected `getty.Serializer` interface value, found `" ++ @typeName(T) ++ "`";

            comptime {
                // Invariants
                if (!std.meta.trait.isContainer(T)) {
                    @compileError(err);
                }

                // Constraints
                const has_name = std.mem.startsWith(u8, @typeName(T), "getty.Serializer");
                const has_field = std.meta.trait.hasField("context")(T);
                const has_decls = std.meta.trait.hasDecls(T, .{ "Ok", "Error" });
                const has_funcs = std.meta.trait.hasFunctions(T, .{
                    "serializeBool",
                    "serializeEnum",
                    "serializeFloat",
                    "serializeInt",
                    "serializeMap",
                    "serializeNull",
                    "serializeSequence",
                    "serializeSome",
                    "serializeString",
                    "serializeStruct",
                    "serializeTuple",
                    "serializeVoid",
                });

                if (!(has_name and has_field and has_decls and has_funcs)) {
                    @compileError(err);
                }
            }
        }

        fn @"getty.Ser"(comptime T: type) void {
            const err = "expected `getty.Ser` interface value, found `" ++ @typeName(T) ++ "`";

            comptime {
                // Invariants
                if (!std.meta.trait.isContainer(T)) {
                    @compileError(err);
                }

                // Constraints
                const has_name = std.mem.startsWith(u8, @typeName(T), "getty.Ser");
                const has_field = std.meta.trait.hasField("context")(T);
                const has_func = std.meta.trait.hasFn("serialize")(T);

                if (!(has_name and has_field and has_func)) {
                    @compileError(err);
                }
            }
        }
    };
};

/// Serializes a value using a provided serializer and `ser`.
///
/// `serializeWith` allows for data types that aren't supported by Getty to be
/// serialized. Additionally, the function enables the use of custom
/// serialization logic for data types that are supported.
pub fn serializeWith(value: anytype, serializer: anytype, s: anytype) blk: {
    ser.concepts.@"getty.Serializer"(@TypeOf(serializer));
    ser.concepts.@"getty.Ser"(@TypeOf(s));

    break :blk @TypeOf(serializer).Error!@TypeOf(serializer).Ok;
} {
    return try s.serialize(value, serializer);
}

/// Serializes a value using a provided serializer and a default `ser`.
///
/// `Ser`s are only provided for data types supported by Getty, plus a few
/// commonly used but unsupported types such as `std.ArrayList` and
/// `std.AutoHashMap`. For custom serialization or serialization of data types
/// not supported Getty, see `getty.serializeWith`.
pub fn serialize(value: anytype, serializer: anytype) blk: {
    ser.concepts.@"getty.Serializer"(@TypeOf(serializer));

    break :blk @TypeOf(serializer).Error!@TypeOf(serializer).Ok;
} {
    const T = @TypeOf(value);

    var s = switch (@typeInfo(T)) {
        .Array => SequenceSer{},
        .Bool => BoolSer{},
        .Enum, .EnumLiteral => EnumSer{},
        .ErrorSet => ErrorSer{},
        .Float, .ComptimeFloat => FloatSer{},
        .Int, .ComptimeInt => IntSer{},
        .Null => NullSer{},
        .Optional => OptionalSer{},
        .Pointer => |info| switch (info.size) {
            .One => PointerSer{},
            .Slice => switch (comptime std.meta.trait.isZigString(T)) {
                true => StringSer{},
                false => SequenceSer{},
            },
            else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
        },
        .Struct => |info| switch (info.is_tuple) {
            false => blk: {
                if (comptime std.mem.startsWith(u8, @typeName(T), "std.array_list")) {
                    break :blk ArrayListSer{};
                } else if (comptime std.mem.startsWith(u8, @typeName(T), "std.hash_map")) {
                    break :blk HashMapSer{};
                } else if (comptime std.mem.startsWith(u8, @typeName(T), "std.linked_list.SinglyLinkedList")) {
                    break :blk LinkedListSer{};
                } else if (comptime std.mem.startsWith(u8, @typeName(T), "std.linked_list.TailQueue")) {
                    break :blk TailQueueSer{};
                } else {
                    break :blk StructSer{};
                }
            },
            true => TupleSer{},
        },
        .Union => UnionSer{},
        .Vector => VectorSer{},
        .Void => VoidSer{},
        else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
    };

    return try serializeWith(value, serializer, s.ser());
}
