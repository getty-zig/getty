//! A serialization and deserialization framework for the Zig programming
//! language.
//!
//! At its core, Getty is composed of two things: a data model (a set of
//! supported types) and data format interfaces (specifications of how to
//! convert between data and format). Together, these components enable any
//! supported data type to be serialized into any conforming data format, and
//! likewise any conforming data format to be deserialized into any data type.
//!
//! By leveraging the powerful compile-time features of Zig, Getty is able to
//! avoid the inherent runtime overhead of more traditional serialization
//! methods such as reflection. Additionally, `comptime` enables all supported
//! data types to automatically become serializable and deserializable.

/// Serialization framework
pub usingnamespace @import("ser.zig");

/// Deserialization framework
pub usingnamespace @import("de.zig");

pub const concepts = struct {
    pub usingnamespace @import("concept/ser.zig");
    pub usingnamespace @import("concept/serializer.zig");
    pub usingnamespace @import("concept/map_serialize.zig");
    pub usingnamespace @import("concept/sequence_serialize.zig");
    pub usingnamespace @import("concept/struct_serialize.zig");
    pub usingnamespace @import("concept/tuple_serialize.zig");
};
