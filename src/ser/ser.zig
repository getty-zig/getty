//! Serialization framework.

/// A `Serializer` serializes values from Getty's data model into a data format.
pub const Serializer = @import("interfaces/serializer.zig").Serializer;

/// Serializes a value into a `getty.Serializer`.
pub const serialize = @import("serialize.zig").serialize;

/// The default serialization tuple used by Getty.
pub const default_st = @import("tuples.zig").default;

/// A namespace containing serialization-specific types and functions.
pub const ser = struct {
    /// Serialization blocks provided by Getty.
    pub const blocks = struct {
        pub usingnamespace @import("blocks.zig");
    };

    /// A generic error set for `getty.Serializer` implementations.
    pub const Error = @import("error.zig").Error;

    /// A `Map` serializes the entries of and ends the serialization process for Getty Maps.
    pub const Map = @import("interfaces/map.zig").Map;

    /// A `Seq` serializes the elements of and ends the serialization process for Getty Sequences.
    pub const Seq = @import("interfaces/seq.zig").Seq;

    /// A `Structure` serializes the fields of and ends the serialization process for Getty Structures.
    pub const Structure = @import("interfaces/structure.zig").Structure;

    /// Constraints that can be used to perform compile-time validation for a
    /// type.
    pub const concepts = @import("concepts.zig");

    /// Functions that can be used to query, at compile-time, the properties of
    /// a type.
    pub const traits = @import("traits.zig");

    /// Returns serialization attributes for `T`. If none exist, `null` is
    /// returned.
    pub const getAttributes = @import("attributes.zig").getAttributes;
};

comptime {
    @import("std").testing.refAllDecls(@This());
}
