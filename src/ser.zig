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
//! # Serializers
//!
//! A serializer defines the conversion process between Getty's data model and
//! an output data format. For example, a JSON serializer would specify that
//! Getty strings should be serialized as `"<INSERT STRING HERE>"`.

const getty = @import("lib.zig");
const std = @import("std");

/// Serializer interface
pub const Serializer = @import("ser/interface/serializer.zig").Serializer;

/// `ser` namespace
pub const ser = struct {
    pub usingnamespace @import("ser/interface/map.zig");
    pub usingnamespace @import("ser/interface/seq.zig");
    pub usingnamespace @import("ser/interface/structure.zig");
    pub usingnamespace @import("ser/interface/tuple.zig");

    pub const default_with = .{
        // Standard Library
        @import("ser/with/array_list.zig"),
        @import("ser/with/hash_map.zig"),
        @import("ser/with/linked_list.zig"),
        @import("ser/with/tail_queue.zig"),

        // Primitives
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
};

pub fn serialize(value: anytype, serializer: anytype) blk: {
    const S = @TypeOf(serializer);
    getty.concepts.@"getty.Serializer"(S);
    break :blk S.Error!S.Ok;
} {
    const T = @TypeOf(value);
    const user_with = @TypeOf(serializer).user_with;
    const ser_with = @TypeOf(serializer).ser_with;

    // User
    if (@TypeOf(user_with) != @TypeOf(ser.default_with)) {
        inline for (user_with) |w| {
            if (comptime w.is(T)) {
                return try w.serialize(value, serializer);
            }
        }
    }

    // Serializer
    if (@TypeOf(ser_with) != @TypeOf(ser.default_with)) {
        inline for (ser_with) |w| {
            if (comptime w.is(T)) {
                return try w.serialize(value, serializer);
            }
        }
    }

    // Default
    inline for (ser.default_with) |w| {
        if (comptime w.is(T)) {
            return try w.serialize(value, serializer);
        }
    }

    @compileError("type `" ++ @typeName(T) ++ "` is not supported");
}
