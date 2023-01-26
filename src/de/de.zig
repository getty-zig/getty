//! Deserialization framework.

/// A `Deserializer` deserializes values from a data format into Getty's data model.
pub const Deserializer = @import("interfaces/deserializer.zig").Deserializer;

/// Deserializes into a value of type `T` from a `getty.Deserializer`.
pub const deserialize = @import("deserialize.zig").deserialize;

/// The default deserialization tuple used by Getty.
pub const default_dt = @import("tuples.zig").default;

/// A namespace containing deserialization-specific types and functions.
pub const de = struct {
    /// Deserialization blocks provided by Getty.
    pub const blocks = struct {
        pub usingnamespace @import("blocks.zig");
    };

    /// A generic error set for `getty.Deserializer` implementations.
    pub const Error = @import("error.zig").Error;

    pub const Visitor = @import("interfaces/visitor.zig").Visitor;

    pub const MapAccess = @import("interfaces/map_access.zig").MapAccess;
    pub const SeqAccess = @import("interfaces/seq_access.zig").SeqAccess;
    pub const UnionAccess = @import("interfaces/union_access.zig").UnionAccess;
    pub const VariantAccess = @import("interfaces/variant_access.zig").VariantAccess;

    pub const Seed = @import("interfaces/seed.zig").Seed;
    pub const DefaultSeed = @import("impls/seed/default.zig").DefaultSeed;
    pub const Ignored = @import("impls/seed/ignored.zig").Ignored;

    /// Constraints that can be used to perform compile-time validation for a type.
    pub const concepts = @import("concepts.zig");

    /// Functions that can be used to query, at compile-time, the properties of a type.
    pub const traits = @import("traits.zig");

    /// Frees resources allocated by Getty during deserialization.
    pub const free = @import("free.zig").free;

    /// Returns deserialization attributes for `T`. If none exist, `null` is returned.
    pub const getAttributes = @import("attributes.zig").getAttributes;

    /// Returns the highest priority Deserialization Block for a type.
    pub const find_db = @import("find.zig").find_db;
};

comptime {
    @import("std").testing.refAllDecls(@This());
}
