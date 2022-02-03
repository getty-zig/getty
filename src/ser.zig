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

const std = @import("std");

const getty = @import("lib.zig");

/// Serializer interface
pub usingnamespace @import("ser/interface/serializer.zig");

/// `ser` namespace
pub const ser = struct {
    pub usingnamespace @import("ser/interface/map.zig");
    pub usingnamespace @import("ser/interface/seq.zig");
    pub usingnamespace @import("ser/interface/structure.zig");
    pub usingnamespace @import("ser/interface/tuple.zig");
};

pub fn serialize(value: anytype, serializer: anytype) blk: {
    const Serializer = @TypeOf(serializer);
    getty.concepts.@"getty.Serializer"(Serializer);

    break :blk Serializer.Error!Serializer.Ok;
} {
    const T = @TypeOf(value);

    if (@TypeOf(serializer).with) |with| {
        inline for (@typeInfo(with).Struct.decls) |decl| {
            const S = @field(with, decl.name);

            if (comptime S.is(T)) {
                return try S.serialize(value, serializer);
            }
        }
    }

    inline for (@typeInfo(default_with).Struct.decls) |decl| {
        const S = @field(default_with, decl.name);

        if (comptime S.is(T)) {
            return try S.serialize(value, serializer);
        }
    }

    @compileError("type `" ++ @typeName(T) ++ "` is not supported");
}

const default_with = struct {
    // Primitives
    const arrays = @import("ser/with/array.zig");
    const bools = @import("ser/with/bool.zig");
    const enums = @import("ser/with/enum.zig");
    const errors = @import("ser/with/error.zig");
    const floats = @import("ser/with/float.zig");
    const ints = @import("ser/with/int.zig");
    const nulls = @import("ser/with/null.zig");
    const optionals = @import("ser/with/optional.zig");
    const pointers = @import("ser/with/pointer.zig");
    const slices = @import("ser/with/slice.zig");
    const strings = @import("ser/with/string.zig");
    const tuples = @import("ser/with/tuple.zig");
    const unions = @import("ser/with/union.zig");
    const vectors = @import("ser/with/vector.zig");
    const voids = @import("ser/with/void.zig");

    // Standard Library
    const array_lists = @import("ser/with/array_list.zig");
    const hash_maps = @import("ser/with/hash_map.zig");
    const linked_lists = @import("ser/with/linked_list.zig");
    const tail_queues = @import("ser/with/tail_queue.zig");

    // Epilogue
    const structs = @import("ser/with/struct.zig");
};
