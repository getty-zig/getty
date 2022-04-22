const std = @import("std");

const IntVisitor = @import("../impls/visitor/int.zig").Visitor;

pub fn is(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .Int, .ComptimeInt => true,
        else => false,
    };
}

pub fn Visitor(comptime T: type) type {
    return IntVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeInt(allocator, visitor);
}
