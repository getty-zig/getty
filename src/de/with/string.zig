const std = @import("std");

const PointerVisitor = @import("../impl/visitor/pointer.zig").Visitor;
const SliceVisitor = @import("../impl/visitor/slice.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.meta.trait.isZigString(T);
}

pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) blk: {
    break :blk switch (@typeInfo(T).Pointer.size) {
        .One => PointerVisitor(T),
        .Slice => SliceVisitor(T),
        else => @compileError("TODO: implement remaining string pointer types"),
    };
} {
    return .{ .allocator = allocator.? };
}

pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
    return try deserializer.deserializeString(v);
}
