/// Specifies the lifetime of a Getty String.
pub const StringLifetime = enum {
    stack,
    heap,
    owned,
};

/// Specifies the lifetime of an access method's return value.
pub const ValueLifetime = enum {
    heap,
    owned,
};
