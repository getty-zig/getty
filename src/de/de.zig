//! Deserialization framework.

/// A namespace containing deserialization-specific types and functions.
pub const de = struct {
    ////////////////////////////////////////////////////////////////////////////////
    // Types
    ////////////////////////////////////////////////////////////////////////////////

    pub const MapAccess = @import("interfaces/map_access.zig").MapAccess;
    pub const SeqAccess = @import("interfaces/seq_access.zig").SeqAccess;
    pub const UnionAccess = @import("interfaces/union_access.zig").UnionAccess;
    pub const VariantAccess = @import("interfaces/variant_access.zig").VariantAccess;

    pub const Visitor = @import("interfaces/visitor.zig").Visitor;

    pub const Seed = @import("interfaces/seed.zig").Seed;
    pub const DefaultSeed = @import("impls/seed/default.zig").DefaultSeed;
    pub const Ignored = @import("impls/seed/ignored.zig").Ignored;

    ////////////////////////////////////////////////////////////////////////////////
    // Namespaces
    ////////////////////////////////////////////////////////////////////////////////

    /// Deserialization blocks provided by Getty.
    pub const blocks = @import("blocks.zig");

    /// Functions that can be used to query, at compile-time, the properties of
    /// a type.
    pub const traits = @import("traits.zig");

    ////////////////////////////////////////////////////////////////////////////////
    // Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// Returns the highest priority Deserialization Block for a type.
    pub const find_db = @import("find.zig").find_db;

    /// Frees resources allocated by Getty during deserialization.
    pub const free = @import("free.zig").free;

    /// Returns deserialization attributes for `T`. If none exist, `null` is returned.
    pub const getAttributes = @import("attributes.zig").getAttributes;

    ////////////////////////////////////////////////////////////////////////////////
    // Error Sets
    ////////////////////////////////////////////////////////////////////////////////

    pub const Error = @import("error.zig").Error;
};

comptime {
    @import("std").testing.refAllDecls(de);
}
