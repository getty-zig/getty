const Allocator = @import("std").mem.Allocator;
const Visitor = @import("../../../lib.zig").de.Visitor;

const Self = @This();

const Value = void;

/// Implements `getty.de.Visitor`.
pub usingnamespace Visitor(
    *Self,
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

fn visitVoid(self: *Self, comptime Error: type) Error!Value {
    _ = self;

    return {};
}
