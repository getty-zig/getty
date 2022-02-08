const getty = @import("../../lib.zig");
const std = @import("std");

const Visitor = @import("../impl/visitor/pointer.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

pub fn visitor(comptime T: type) Visitor(T) {
    return .{};
}

pub fn deserialize(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    const Child = std.meta.Child(T);
    const db = getty.de.find_db(@TypeOf(deserializer), Child);

    return try db.deserialize(allocator, Child, deserializer, v);
}
