const Allocator = @import("std").mem.Allocator;
const Visitor = @import("../../interface.zig").Visitor;

const Self = @This();

const Value = void;

/// Implements `getty.de.Visitor`.
pub usingnamespace Visitor(
    *Self,
    Value,
    visitBool,
    visitEnum,
    visitFloat,
    visitInt,
    visitMap,
    visitNull,
    visitSequence,
    visitSlice,
    visitSome,
    visitVoid,
);

fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
    _ = self;
    _ = input;

    @panic("Unsupported");
}

fn visitEnum(self: *Self, comptime Error: type, input: anytype) Error!Value {
    _ = self;
    _ = input;

    @panic("Unsupported");
}

fn visitFloat(self: *Self, comptime Error: type, input: anytype) Error!Value {
    _ = self;
    _ = input;

    @panic("Unsupported");
}

fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
    _ = self;
    _ = input;

    @panic("Unsupported");
}

fn visitMap(self: *Self, allocator: ?*Allocator, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
    _ = self;
    _ = allocator;

    @panic("Unsupported");
}

fn visitNull(self: *Self, comptime Error: type) Error!Value {
    _ = self;

    @panic("Unsupported");
}

fn visitSequence(self: *Self, seqAccess: anytype) @TypeOf(seqAccess).Error!Value {
    _ = self;

    @panic("Unsupported");
}

fn visitSlice(self: *Self, allocator: *Allocator, comptime Error: type, input: anytype) Error!Value {
    _ = self;
    _ = allocator;
    _ = input;

    @panic("Unsupported");
}

fn visitSome(self: *Self, allocator: ?*Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
    _ = self;
    _ = allocator;

    @panic("Unsupported");
}

fn visitVoid(self: *Self, comptime Error: type) Error!Value {
    _ = self;

    return {};
}
