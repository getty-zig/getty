const std = @import("std");

const Visitor = @import("../impl/visitor/array.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Array;
}

pub fn visitor(_: ?std.mem.Allocator, comptime T: type) Visitor(T) {
    return .{};
}

pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeSeq(v);
}
