//! A serialization and deserialization framework for the Zig programming
//! language.
//!
//! The main contribution of Getty is its data model, a set of types that
//! establishes a generic baseline from which serializers and deserializers can
//! operate. By working within Getty's data model, the set of possible
//! inputs/outputs for a serializer/deserializer is reduced from all possible
//! types in Zig to a subset of the types within the data model.
//!
//! Any type that is mapped to Getty's data model automatically becomes
//! (de)serializable. Out of the box, Getty maps a number of Zig types,
//! including many standard library types (e.g., std.ArrayList,
//! std.StringHashMap). For types that aren't already supported by Getty,
//! custom "blocks" can be provided to specify how a type can be serialized or
//! deserialized into.

const s = @import("ser.zig");
const d = @import("de.zig");

/// Serialization framework.
pub const Serializer = s.Serializer;
pub const default_st = s.default_st;
pub const ser = s.ser;
pub const serialize = s.serialize;

/// Deserialization framework.
/// Attributes.
pub usingnamespace @import("attributes.zig");

/// Compile-time type restraints for various Getty data types.
pub const concepts = struct {
    pub usingnamespace s.concepts;
    pub usingnamespace d.concepts;
};

pub const traits = struct {
    pub usingnamespace s.traits;
    pub usingnamespace d.traits;
};

/// Placeholder value for compound (de)serialization-related arguments.
pub const TODO = struct {};
