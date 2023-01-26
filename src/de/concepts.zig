/// Specifies that a type is a `getty.Deserializer` interface type.
pub const @"getty.Deserializer" = @import("concepts/deserializer.zig").@"getty.Deserializer";

/// Specifies that a type is a `getty.de.Visitor` interface type.
pub const @"getty.de.Visitor" = @import("concepts/visitor.zig").@"getty.de.Visitor";

/// Specifies that a type is a `getty.de.MapAccess` interface type.
pub const @"getty.de.MapAccess" = @import("concepts/map_access.zig").@"getty.de.MapAccess";

/// Specifies that a type is a `getty.de.SeqAccess` interface type.
pub const @"getty.de.SeqAccess" = @import("concepts/seq_access.zig").@"getty.de.SeqAccess";

/// Specifies that a type is a `getty.de.UnionAccess` interface type.
pub const @"getty.de.UnionAccess" = @import("concepts/union_access.zig").@"getty.de.UnionAccess";

/// Specifies that a type is a `getty.de.VariantAccess` interface type.
pub const @"getty.de.VariantAccess" = @import("concepts/variant_access.zig").@"getty.de.VariantAccess";

/// Specifies that a type is a `getty.de.Seed` interface type.
pub const @"getty.de.Seed" = @import("concepts/seed.zig").@"getty.de.Seed";

/// Specifies that a type is a deserialization block or tuple.
pub const @"getty.de.dbt" = @import("concepts/block.zig").@"getty.de.dbt";
