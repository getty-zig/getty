const std = @import("std");

const Visitor = @import("../impl/visitor/int.zig").Visitor;

pub fn is(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .Int, .ComptimeInt => true,
        else => false,
    };
}

pub fn visitor(comptime T: type) Visitor(T) {
    return .{};
}

pub fn deserialize(allocator: ?std.mem.Allocator, comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeInt(allocator, v);
}
