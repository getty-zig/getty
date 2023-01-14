const std = @import("std");
const t = @import("getty/testing");

const StructVisitor = @import("../impls/visitor/struct.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeStruct(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return StructVisitor(T);
}

test "deserialize - struct" {
    try t.de.run(deserialize, Visitor, &.{
        .{ .Struct = .{ .name = "", .len = 0 } },
        .{ .StructEnd = {} },
    }, struct {}{});

    const T = struct { a: i32, b: i32, c: i32 };

    try t.de.run(deserialize, Visitor, &.{
        .{ .Struct = .{ .name = "T", .len = 3 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .String = "c" },
        .{ .I32 = 3 },
        .{ .StructEnd = {} },
    }, T{ .a = 1, .b = 2, .c = 3 });
}
