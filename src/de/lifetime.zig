/// The lifetime of the Getty String passed to a visitor's `visitString`
/// method.
pub const StringLifetime = enum {
    stack,
    heap,
    managed,
};

/// The lifetime of an access method's return value.
pub const ValueLifetime = enum {
    heap,
    managed,
};
