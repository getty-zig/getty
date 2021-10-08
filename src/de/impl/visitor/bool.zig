const de = @import("../../../lib.zig").de;

const Value = bool;

/// Implements `getty.de.Visitor`.
pub usingnamespace de.Visitor(
    *@This(),
    Value,
    visitBool,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
);

fn visitBool(_: *@This(), comptime Error: type, input: bool) Error!Value {
    return input;
}
