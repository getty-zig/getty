const std = @import("std");

const Visitor = @import("../impl/visitor/array_list.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "std.array_list");
}

pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) Visitor(T) {
    return .{ .allocator = allocator.? };
}

pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeSequence(v);
}
