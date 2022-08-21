const std = @import("std");

const LinkedListVisitor = @import("../impls/visitor/linked_list.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "linked_list.SinglyLinkedList");
}

pub fn Visitor(comptime T: type) type {
    return LinkedListVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeSeq(allocator, visitor);
}
