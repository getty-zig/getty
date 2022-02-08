const std = @import("std");

const Visitor = @import("../impl/visitor/float.zig").Visitor;

pub fn is(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => true,
        else => false,
    };
}

pub fn visitor(comptime T: type) Visitor(T) {
    return .{};
}

pub fn deserialize(allocator: ?std.mem.Allocator, comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeFloat(allocator, v);
}
