//! Serialization framework.
//!
//! Visually, serialization in Getty can be represented like so:
//!
//!                  Zig data
//!
//!                     ↓          <-----------------------
//!                                                       |
//!              Getty Data Model                         |
//!                                                       |
//!                     ↓          <-------               |
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
//!   11. Tuple
//!   12. Void
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
pub const Serializer = @import("ser/interface/serializer.zig").Serializer;

/// Namespace for serialization-specific types and functions.
pub const ser = struct {
    /// Map serialization interface.
    pub usingnamespace @import("ser/interface/map.zig");

    /// Sequence serialization interface.
    pub usingnamespace @import("ser/interface/seq.zig");

    /// Struct serialization interface.
    pub usingnamespace @import("ser/interface/structure.zig");

    /// Tuple serialization interface.
    pub usingnamespace @import("ser/interface/tuple.zig");
};

/// The default Serialization Tuple.
///
/// If a user or serializer ST is provided, the default ST is appended to
/// the end, thereby taking the lowest priority.
pub const default_st = .{
    // std
    @import("ser/with/array_list.zig"),
    @import("ser/with/hash_map.zig"),
    @import("ser/with/linked_list.zig"),
    @import("ser/with/tail_queue.zig"),

    // primitives
    @import("ser/with/array.zig"),
    @import("ser/with/bool.zig"),
    @import("ser/with/enum.zig"),
    @import("ser/with/error.zig"),
    @import("ser/with/float.zig"),
    @import("ser/with/int.zig"),
    @import("ser/with/null.zig"),
    @import("ser/with/optional.zig"),
    @import("ser/with/pointer.zig"),
    @import("ser/with/slice.zig"),
    @import("ser/with/string.zig"),
    @import("ser/with/struct.zig"),
    @import("ser/with/tuple.zig"),
    @import("ser/with/union.zig"),
    @import("ser/with/vector.zig"),
    @import("ser/with/void.zig"),
};

/// Serializes a value into the given Getty serializer.
pub fn serialize(value: anytype, serializer: anytype) blk: {
    const S = @TypeOf(serializer);

    getty.concepts.@"getty.Serializer"(S);

    break :blk S.Error!S.Ok;
} {
    const T = @TypeOf(value);

    inline for (@TypeOf(serializer).with) |w| {
        if (comptime w.is(T)) {
            return try w.serialize(value, serializer);
        }
    }

    @compileError("type `" ++ @typeName(T) ++ "` is not supported");
}
