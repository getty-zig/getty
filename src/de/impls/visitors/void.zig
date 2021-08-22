const de = @import("../../../lib.zig").de;

const Self = @This();

const Value = void;

/// Implements `getty.de.Visitor`.
pub fn visitor(self: *Self) V {
    return .{ .context = self };
}

const V = de.Visitor(
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
