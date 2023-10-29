const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

const Visitor = @This();

pub usingnamespace VisitorInterface(
    Visitor,
    Value,
    .{ .visitBool = visitBool },
);

const Value = bool;

fn visitBool(
    _: Visitor,
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
    input: bool,
) Deserializer.Err!Value {
    _ = result_ally;
    _ = scratch_ally;

    return input;
}
