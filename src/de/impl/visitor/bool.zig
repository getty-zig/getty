const Allocator = @import("std").mem.Allocator;
const de = @import("../../../lib.zig").de;

const Self = @This();

const Value = bool;

/// Implements `getty.de.Visitor`.
pub usingnamespace de.Visitor(
    *Self,
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

fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
    _ = self;

    return input;
}
