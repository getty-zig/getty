//! A (de)serialization framework for the Zig programming language.

const s = @import("ser.zig");
const d = @import("de.zig");

/// The serializer interface.
pub const Serializer = s.Serializer;

/// The default Serialization Tuple.
pub const default_st = s.default_st;

/// Serializes a value into the given Getty serializer.
pub const serialize = s.serialize;

/// The serialization namespace.
pub const ser = s.ser;

/// The deserializer interface.
pub const Deserializer = d.Deserializer;

/// The default Deserialization Tuple.
pub const default_dt = d.default_dt;

/// Deserializes a value from the given Getty deserializer.
pub const deserialize = d.deserialize;

/// The deserialization namespace.
pub const de = d.de;

/// TODO: Document this.
pub usingnamespace @import("attributes.zig");

/// Compile-time type restraints for various Getty data types.
pub const concepts = struct {
    pub usingnamespace s.concepts;
    pub usingnamespace d.concepts;
};

/// Functions for obtaining type information at compile-time.
pub const traits = struct {
    pub usingnamespace s.traits;
    pub usingnamespace d.traits;
};

/// Placeholder value for aggregate (de)serialization-related arguments.
pub const TODO = struct {};
