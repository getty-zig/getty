const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

const Visitor = @This();

pub usingnamespace VisitorInterface(
    Visitor,
    Value,
    .{ .visitBool = visitBool },
);

const Value = bool;

fn visitBool(_: Visitor, _: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
    return input;
}
