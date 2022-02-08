const std = @import("std");

const Visitor = @import("../impl/visitor/struct.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
}

pub fn visitor(comptime T: type) Visitor(T) {
    return .{};
}

pub fn deserialize(allocator: ?std.mem.Allocator, comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeStruct(allocator, v);
}
