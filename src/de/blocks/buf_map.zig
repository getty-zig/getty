const std = @import("std");
const t = @import("getty/testing");

const BufMapVisitor = @import("../impls/visitor/buf_map.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == std.BufMap;
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

    return try deserializer.deserializeMap(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return BufMapVisitor(T);
}

test "deserialize - buf map" {
    {
        var expected = std.BufMap.init(std.testing.allocator);
        defer expected.deinit();

        try t.de.run(deserialize, Visitor, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        }, expected);
    }

    {
        var expected = std.BufMap.init(std.testing.allocator);
        defer expected.deinit();

        try expected.put("one", "foo");
        try expected.put("two", "bar");
        try expected.put("three", "baz");

        try t.de.run(deserialize, Visitor, &.{
            .{ .Map = .{ .len = 3 } },
            .{ .String = "one" },
            .{ .String = "foo" },
            .{ .String = "two" },
            .{ .String = "bar" },
            .{ .String = "three" },
            .{ .String = "baz" },
            .{ .MapEnd = {} },
        }, expected);
    }
}
