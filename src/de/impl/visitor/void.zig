const Visitor = @import("../../../lib.zig").de.Visitor;

const Value = void;

/// Implements `getty.de.Visitor`.
pub usingnamespace Visitor(
    *@This(),
    Value,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    visitVoid,
);

fn visitVoid(_: *@This(), comptime Error: type) Error!Value {
    return {};
}
