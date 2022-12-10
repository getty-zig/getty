const std = @import("std");

/// A generic error set for `getty.de.Visitor` implementations.
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
