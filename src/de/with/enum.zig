const std = @import("std");

const Visitor = @import("../impl/visitor/enum.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Enum;
}

pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) Visitor(T) {
    return .{ .allocator = allocator };
}

pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeEnum(v);
}
