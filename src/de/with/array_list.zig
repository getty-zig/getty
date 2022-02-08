const std = @import("std");

const ArrayListVisitor = @import("../impl/visitor/array_list.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "std.array_list");
}

pub fn Visitor(comptime T: type) type {
    return ArrayListVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeSeq(allocator, visitor);
}
