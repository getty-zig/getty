//! A (de)serialization framework for the Zig programming language.

pub const de = @import("de/de.zig").de;
pub const ser = @import("ser/ser.zig");

pub const Deserializer = @import("de/interfaces/deserializer.zig").Deserializer;
pub const Serializer = @import("ser/interfaces/serializer.zig").Serializer;

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

/// Deserializes data from the `getty.Deserializer` `d` into a managed value of
/// type `T`.
pub const deserialize = @import("de/deserialize.zig").deserialize;

/// Deserializes data from the `getty.Deserializer` `d` into an umanaged value
/// of type `T`.
pub const deserializeLeaky = @import("de/deserialize.zig").deserializeLeaky;

/// `serialize` converts the value `v` into formatted data using the
/// `getty.Serializer` `s`.
pub const serialize = @import("ser/serialize.zig").serialize;

////////////////////////////////////////////////////////////////////////////////
// Values
////////////////////////////////////////////////////////////////////////////////

/// `dt` is Getty's default _Deserialization Tuple_.
pub const dt = @import("de/tuples.zig").dt;

/// `st` is Getty's default _Serialization Tuple_.
pub const st = @import("ser/tuples.zig").st;

////////////////////////////////////////////////////////////////////////////////
// Testing
////////////////////////////////////////////////////////////////////////////////

comptime {
    @import("std").testing.refAllDecls(@This());
}
