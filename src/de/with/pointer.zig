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

    inline for (@TypeOf(deserializer).with) |w| {
        if (comptime w.is(Child)) {
            return try w.deserialize(Child, deserializer, v);
        }
    }
}
