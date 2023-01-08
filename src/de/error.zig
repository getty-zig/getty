const std = @import("std");

/// A generic error set for `getty.Deserializer` implementations.
///
/// This error set must always be included in a `getty.Deserializer`
/// implementation's error set.
pub const Error = std.mem.Allocator.Error || error{
    DuplicateField,
    InvalidLength,
    InvalidType,
    InvalidValue,
    MissingField,
    MissingVariant,
    UnknownField,
    UnknownVariant,
    Unsupported,
};
