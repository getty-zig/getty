const std = @import("std");
const t = @import("getty/testing");

const TupleVisitor = @import("../impls/visitor/tuple.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Struct and @typeInfo(T).Struct.is_tuple;
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

    return try deserializer.deserializeSeq(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return TupleVisitor(T);
}

test "deserialize - tuple" {
    try t.de.run(&[_]t.Token{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .U32 = 2 },
        .{ .SeqEnd = {} },
    }, std.meta.Tuple(&[_]type{ i32, u32 }){ 1, 2 });

    //try t.de.run(&[_]t.Token{
    //.{ .Seq = .{ .len = 3 } },
    //.{ .Seq = .{ .len = 2 } },
    //.{ .I32 = 1 },
    //.{ .I32 = 2 },
    //.{ .SeqEnd = {} },
    //.{ .Seq = .{ .len = 2 } },
    //.{ .I32 = 3 },
    //.{ .I32 = 4 },
    //.{ .SeqEnd = {} },
    //.{ .Seq = .{ .len = 2 } },
    //.{ .I32 = 5 },
    //.{ .I32 = 6 },
    //.{ .SeqEnd = {} },
    //.{ .SeqEnd = {} },
    //}, std.meta.Tuple(&[_]type{
    //std.meta.Tuple(&[_]type{ i32, i32 }),
    //std.meta.Tuple(&[_]type{ i32, i32 }),
    //std.meta.Tuple(&[_]type{ i32, i32 }),
    //}){ .{ 1, 2 }, .{ 3, 4 }, .{ 5, 6 } });
}
