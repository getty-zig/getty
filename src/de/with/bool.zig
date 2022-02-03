const std = @import("std");

const Visitor = @import("../impl/visitor/bool.zig");

pub fn is(comptime T: type) bool {
    return T == bool;
}

pub fn visitor(_: ?std.mem.Allocator, comptime _: type) Visitor {
    return .{};
}

pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeBool(v);
}
