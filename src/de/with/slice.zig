const std = @import("std");

const Visitor = @import("../impl/visitor/slice.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice and comptime !std.meta.trait.isZigString(T);
}

pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) Visitor(T) {
    return .{ .allocator = allocator.? };
}

pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeSequence(v);
}
