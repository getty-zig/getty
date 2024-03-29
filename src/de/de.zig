/// The `de` namespace provides deserialization-specific types and functions.
pub const de = struct {
    ////////////////////////////////////////////////////////////////////////////////
    // Types
    ////////////////////////////////////////////////////////////////////////////////

    /// A managed, deserialized value.
    pub const Result = @import("deserialize.zig").Result;

    /// The return value of a `getty.de.Visitor`'s `visitString` method.
    pub const VisitStringReturn = @import("interfaces/visitor.zig").VisitStringReturn;

    /// Deserialization and access interface for Getty Maps.
    pub const MapAccess = @import("interfaces/map_access.zig").MapAccess;

    /// Deserialization and access interface for Getty Sequences.
    pub const SeqAccess = @import("interfaces/seq_access.zig").SeqAccess;

    /// Deserialization and access interface for Getty Unions.
    pub const UnionAccess = @import("interfaces/union_access.zig").UnionAccess;

    /// Deserialization and access interface for variants of Getty Unions.
    pub const VariantAccess = @import("interfaces/variant_access.zig").VariantAccess;

    /// A `Visitor` deserializes values from Getty's data model into Zig.
    pub const Visitor = @import("interfaces/visitor.zig").Visitor;

    /// A `Seed` facilitates stateful deserialization.
    pub const Seed = @import("interfaces/seed.zig").Seed;

    /// The default implementation of `getty.de.Seed`.
    pub const DefaultSeed = @import("impls/seed/default.zig").DefaultSeed;

    /// An implementation of `getty.de.Seed` that ignores values.
    pub const Ignored = @import("impls/seed/ignored.zig").Ignored;

    /// The lifetime of the Getty String passed to a visitor's `visitString`
    /// method.
    pub const StringLifetime = @import("lifetime.zig").StringLifetime;

    /// The lifetime of an access method's return value.
    pub const ValueLifetime = @import("lifetime.zig").ValueLifetime;

    ////////////////////////////////////////////////////////////////////////////////
    // Namespaces
    ////////////////////////////////////////////////////////////////////////////////

    /// Getty's default deserialization blocks.
    pub const blocks = @import("blocks.zig");

    ////////////////////////////////////////////////////////////////////////////////
    // Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// Returns the highest priority Deserialization Block for a type.
    pub const find_db = @import("find.zig").find_db;

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
