const getty = @import("../../lib.zig");
const std = @import("std");

const Visitor = @import("../impl/visitor/pointer.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) Visitor(T) {
    return .{ .allocator = allocator.? };
}

pub fn deserialize(comptime T: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    const Child = std.meta.Child(T);
    const With = getty.With(@TypeOf(deserializer), Child);

    return try With.deserialize(Child, deserializer, v);
}
