//! Serialization framework.
//!
//! Visually, serialization in Getty can be represented like so:
//!
//!                  Zig data
//!
//!                     |          <-----------------------
//!                     ▼                                 |
//!                                                       |
//!              Getty Data Model                         |
//!                                                       |
//!                     |          <-------               |
//!                     ▼                 |               |
//!                                       |               |
//!                Data Format            |               |
//!                                       |               |
//!                                       |
//!                                       |      Serialization Block
//!                                       |
//!
//!                               `getty.Serializer`
//!
//! Data Model
//! ==========
//!
//! The Getty Data Model (GDM) is the set of types supported by Getty. The
//! types within the GDM are purely conceptual; they aren't actual Zig types.
//! For example, there is no `i32` or `u64` in the GDM. Instead, they are both
//! considered to be the type: integer.
//!
//! By maintaining a data model, Getty establishes a generic baseline from
//! which serializers can operate. This often simplifies the job of a
//! serializer significantly. For example, Zig considers `struct { x: i32 }`
//! and `struct { y: bool }` to be different types. However, in Getty they are
//! both considered to be the same type: struct. This means that if a
//! serializer knows how to serialize a struct (as defined by the GDM), then it
//! will be able to serialize `struct { x: i32 }` values, `struct { y: bool }`
//! values, and values of any other struct type that is composed of data types
//! supported by Getty.
//!
//! The serialization GDM consists of the following types:
//!
//!   1. Boolean
//!   2. Enum
//!   3. Float
//!   4. Integer
//!   5. Map
//!   6. Null
//!   7. Sequence
//!   8. Some
//!   9. String
//!   10. Struct
//!   11. Void
//!
//! Serializers
//! ===========
//!
//! A serializer is an implementation of the `getty.Serializer` interface. They
//! define the conversion process between Getty's data model and an output data
//! format (e.g., JSON, YAML). For example, a JSON serializer would be
//! responsible for converting Getty maps into JSON maps.
//!
//! Serialization Blocks
//! ====================
//!
//! Serialization Blocks (SB) make up the core of custom serialization in
//! Getty. SBs define how to serialize values of one or more types.
//!
//! An SB is a struct namespace containing two functions:
//!
//!   1. fn is(comptime T: type) bool
//!   2. fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok
//!
//! The `is` function specifies which types are serializable by the SB, and the
//! `serialize` function defines how to serialize values of those types.
//!
//! For example, the following shows an SB for booleans:
//!
//! ```zig
//! const bool_sb = struct {
//!     pub fn is(comptime T: type) bool {
//!         return T == bool;
//!     }
//!
//!     pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
//!         return try serializer.serializeBool(value);
//!     }
//! };
//! ```
//!
//! Serialization Tuples
//! ====================
//!
//! SBs can be grouped up into a tuple, known as a Serialization Tuple (ST).
//!
//! Getty provides its own ST for various Zig data types, but users and
//! serializers can provide their own through the `getty.Serializer` interface.

const getty = @import("lib.zig");
const std = @import("std");

/// Serializer interface.
pub const Serializer = @import("ser/interfaces/serializer.zig").Serializer;

/// Namespace for serialization-specific types and functions.
pub const ser = struct {
    /// Map serialization interface.
    pub usingnamespace @import("ser/interfaces/map.zig");

    /// Sequence serialization interface.
    pub usingnamespace @import("ser/interfaces/seq.zig");

    /// Struct serialization interface.
    pub usingnamespace @import("ser/interfaces/structure.zig");

    pub const blocks = struct {
        // std
        pub const ArrayList = @import("ser/blocks/array_list.zig");
        pub const BoundedArray = @import("ser/blocks/bounded_array.zig");
        pub const HashMap = @import("ser/blocks/hash_map.zig");
        pub const LinkedList = @import("ser/blocks/linked_list.zig");
        pub const TailQueue = @import("ser/blocks/tail_queue.zig");

        // primitives
        pub const Array = @import("ser/blocks/array.zig");
        pub const Bool = @import("ser/blocks/bool.zig");
        pub const Enum = @import("ser/blocks/enum.zig");
        pub const Error = @import("ser/blocks/error.zig");
        pub const Float = @import("ser/blocks/float.zig");
        pub const Int = @import("ser/blocks/int.zig");
        pub const Null = @import("ser/blocks/null.zig");
        pub const Optional = @import("ser/blocks/optional.zig");
        pub const Pointer = @import("ser/blocks/pointer.zig");
        pub const Slice = @import("ser/blocks/slice.zig");
        pub const String = @import("ser/blocks/string.zig");
        pub const Struct = @import("ser/blocks/struct.zig");
        pub const Tuple = @import("ser/blocks/tuple.zig");
        pub const Union = @import("ser/blocks/union.zig");
        pub const Vector = @import("ser/blocks/vector.zig");
        pub const Void = @import("ser/blocks/void.zig");
    };
};

/// The default Serialization Tuple.
///
/// If a user or serializer ST is provided, the default ST is appended to
/// the end, thereby taking the lowest priority.
pub const default_st = .{
    // std
    ser.blocks.ArrayList,
    ser.blocks.BoundedArray,
    ser.blocks.HashMap,
    ser.blocks.LinkedList,
    ser.blocks.TailQueue,

    // primitives
    ser.blocks.Array,
    ser.blocks.Bool,
    ser.blocks.Enum,
    ser.blocks.Error,
    ser.blocks.Float,
    ser.blocks.Int,
    ser.blocks.Null,
    ser.blocks.Optional,
    ser.blocks.Pointer,
    ser.blocks.Slice,
    ser.blocks.String,
    ser.blocks.Struct,
    ser.blocks.Tuple,
    ser.blocks.Union,
    ser.blocks.Vector,
    ser.blocks.Void,
};

/// Serializes a value into the given Getty serializer.
pub fn serialize(value: anytype, serializer: anytype) blk: {
    const S = @TypeOf(serializer);

    getty.concepts.@"getty.Serializer"(S);

    break :blk S.Error!S.Ok;
} {
    const T = @TypeOf(value);

    // Check user SBTs.
    inline for (@TypeOf(serializer).user_st) |sb| {
        if (comptime sb.is(T)) {
            if (@hasDecl(sb, "attributes")) {
                return try switch (@typeInfo(T)) {
                    .Struct => ser.blocks.Struct.serialize(value, serializer),
                    .Enum => ser.blocks.Enum.serialize(value, serializer),
                    .Union => ser.blocks.Union.serialize(value, serializer),
                    // TODO: Need to validate attributes.
                    else => unreachable,
                };
            } else {
                return try sb.serialize(value, serializer);
            }
        }
    }

    // Check type SBTs.
    if (comptime std.meta.trait.isContainer(T) and
        std.meta.trait.hasDecls(T, .{"getty.sbt"}) and
        getty.concepts.traits.is_sbt(T.@"getty.sbt"))
    {
        const type_sbt = T.@"getty.sbt";
        const type_tuple = if (@TypeOf(type_sbt) == type) .{type_sbt} else type_sbt;

        inline for (type_tuple) |sb| {
            if (comptime sb.is(T)) {
                if (@hasDecl(sb, "attributes")) {
                    return try switch (@typeInfo(T)) {
                        .Struct => ser.blocks.Struct.serialize(value, serializer),
                        .Enum => ser.blocks.Enum.serialize(value, serializer),
                        .Union => ser.blocks.Union.serialize(value, serializer),
                        // TODO: Need to validate attributes.
                        else => unreachable,
                    };
                } else {
                    return try sb.serialize(value, serializer);
                }
            }
        }
    }

    // Check serializer SBTs.
    inline for (@TypeOf(serializer).serializer_st) |sb| {
        if (comptime sb.is(T)) {
            if (@hasDecl(sb, "attributes")) {
                return try switch (@typeInfo(T)) {
                    .Struct => ser.blocks.Struct.serialize(value, serializer),
                    .Enum => ser.blocks.Enum.serialize(value, serializer),
                    .Union => ser.blocks.Union.serialize(value, serializer),
                    // TODO: Need to validate attributes.
                    else => unreachable,
                };
            } else {
                return try sb.serialize(value, serializer);
            }
        }
    }

    // Check default SBTs.
    inline for (default_st) |sb| {
        if (comptime sb.is(T)) {
            return try sb.serialize(value, serializer);
        }
    }

    @compileError("type `" ++ @typeName(T) ++ "` is not supported");
}
