const std = @import("std");

const HashMapVisitor = @import("../impls/visitor/hash_map.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "hash_map");
}

pub fn Visitor(comptime T: type) type {
    return HashMapVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeMap(allocator, visitor);
}
