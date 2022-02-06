const std = @import("std");

const Visitor = @import("../impl/visitor/slice.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice;
}

pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) Visitor(T) {
    return .{ .allocator = allocator.? };
}

pub fn deserialize(comptime T: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try switch (comptime std.meta.trait.isZigString(T)) {
        true => deserializer.deserializeString(v),
        false => deserializer.deserializeSequence(v),
    };
}
