const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

const Visitor = @This();

pub usingnamespace VisitorInterface(
    Visitor,
    Value,
    .{ .visitVoid = visitVoid },
);

const Value = void;

fn visitVoid(_: Visitor, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
    return {};
}
