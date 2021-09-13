//! Getty is a serialization and deserialization framework for the Zig
//! programming language.
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

pub usingnamespace @import("ser.zig");
pub usingnamespace @import("de.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
