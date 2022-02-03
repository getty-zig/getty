const std = @import("std");

const Visitor = @import("../impl/visitor/hash_map.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "std.hash_map");
}

pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) Visitor(T) {
    return .{ .allocator = allocator.? };
}

pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeMap(v);
}
