const std = @import("std");

const Visitor = @import("../impl/visitor/slice.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice;
}

pub fn visitor(comptime T: type) Visitor(T) {
    return .{};
}

pub fn deserialize(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try switch (comptime std.meta.trait.isZigString(T)) {
        true => deserializer.deserializeString(allocator, v),
        false => deserializer.deserializeSeq(allocator, v),
    };
}
