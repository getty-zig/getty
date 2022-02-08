const std = @import("std");

const Visitor = @import("../impl/visitor/hash_map.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "std.hash_map");
}

pub fn visitor(comptime T: type) Visitor(T) {
    return .{};
}

pub fn deserialize(allocator: ?std.mem.Allocator, comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeMap(allocator, v);
}
