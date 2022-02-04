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
};

const default_with = @import("ser/interface/serializer.zig").default_with;

pub fn serialize(value: anytype, serializer: anytype) blk: {
    const S = @TypeOf(serializer);
    getty.concepts.@"getty.Serializer"(S);
    break :blk S.Error!S.Ok;
} {
    const T = @TypeOf(value);

    if (@TypeOf(serializer).with) |with| {
        inline for (with) |w| {
            if (comptime w.is(T)) {
                return try w.serialize(value, serializer);
            }
        }
    }

    inline for (default_with) |with| {
        if (comptime with.is(T)) {
            return try with.serialize(value, serializer);
        }
    }

    @compileError("type `" ++ @typeName(T) ++ "` is not supported");
}
