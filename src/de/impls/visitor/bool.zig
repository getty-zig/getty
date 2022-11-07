const std = @import("std");

const de = @import("../../../de.zig").de;

const Visitor = @This();

pub usingnamespace de.Visitor(
    Visitor,
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
    undefined,
);

const Value = bool;

fn visitBool(_: Visitor, _: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
    return input;
}
