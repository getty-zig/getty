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

/// Serialization framework.
pub usingnamespace @import("ser.zig");

/// Deserialization framework.
pub usingnamespace @import("de.zig");

/// Compile-time type restraints for various Getty data types.
pub const concepts = struct {
    pub usingnamespace @import("ser/concepts/map.zig");
    pub usingnamespace @import("ser/concepts/sbt.zig");
    pub usingnamespace @import("ser/concepts/serializer.zig");
    pub usingnamespace @import("ser/concepts/seq.zig");
    pub usingnamespace @import("ser/concepts/structure.zig");

    pub usingnamespace @import("de/concepts/dbt.zig");
    pub usingnamespace @import("de/concepts/deserializer.zig");
    pub usingnamespace @import("de/concepts/map.zig");
    pub usingnamespace @import("de/concepts/seed.zig");
    pub usingnamespace @import("de/concepts/seq.zig");
    pub usingnamespace @import("de/concepts/visitor.zig");

    pub fn err(comptime concept: []const u8, comptime msg: []const u8) void {
        @compileError("concept `" ++ concept ++ "` was not satisfied: " ++ msg);
    }
};
