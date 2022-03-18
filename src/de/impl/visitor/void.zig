const getty = @import("../../../lib.zig");
const std = @import("std");

const Visitor = @This();

pub usingnamespace getty.de.Visitor(
    Visitor,
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

const Value = void;

fn visitVoid(_: Visitor, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
    return {};
}
