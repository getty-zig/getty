//! The `ser` namespace provides serialization-specific declarations.

////////////////////////////////////////////////////////////////////////////////
// Namespaces
////////////////////////////////////////////////////////////////////////////////

pub const blocks = @import("blocks.zig");

////////////////////////////////////////////////////////////////////////////////
// Types
////////////////////////////////////////////////////////////////////////////////

/// A `Map` serializes the entries of and ends the serialization process for
/// _Getty Maps_.
pub const Map = @import("interfaces/map.zig").Map;

/// A `Seq` serializes the elements of and ends the serialization process for
/// _Getty Sequences_.
pub const Seq = @import("interfaces/seq.zig").Seq;

/// A `Structure` serializes the fields of and ends the serialization process
/// for _Getty Structures_.
pub const Structure = @import("interfaces/structure.zig").Structure;

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

/// `getAttributes` returns attributes for `T`, given a `getty.Serializer`
/// interface type `S`.
///
/// If no serialization attributes are found, `null` is returned.
pub const getAttributes = @import("attributes.zig").getAttributes;

////////////////////////////////////////////////////////////////////////////////
// Error Sets
////////////////////////////////////////////////////////////////////////////////

/// A generic error set for `getty.Serializer` implementations.
///
/// This error set must always be included in a `getty.Serializer`
/// implementation's error set.
pub const Error = @import("error.zig").Error;

comptime {
    @import("std").testing.refAllDecls(@This());
}
