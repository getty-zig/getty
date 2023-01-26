const std = @import("std");
const t = @import("../testing.zig");

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
    {
        const T = struct {};
        const tokens = &.{
            .{ .Struct = .{ .name = @typeName(T), .len = 0 } },
            .{ .StructEnd = {} },
        };
        const expected = T{};

        try t.run(deserialize, Visitor, tokens, expected);
    }

    {
        const T = struct {
            a: i32,
            b: i32,
            c: i32,
        };
        const tokens = &.{
            .{ .Struct = .{ .name = @typeName(T), .len = 3 } },
            .{ .String = "a" },
            .{ .I32 = 1 },
            .{ .String = "b" },
            .{ .I32 = 2 },
            .{ .String = "c" },
            .{ .I32 = 3 },
            .{ .StructEnd = {} },
        };
        const expected = T{ .a = 1, .b = 2, .c = 3 };

        try t.run(deserialize, Visitor, tokens, expected);
    }
}

test "deserialize - struct, attributes (ignore_unknown_fields)" {
    const T = struct {
        a: i32,
        b: i32,
        c: i32,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .Container = .{ .ignore_unknown_fields = true },
            };
        };
    };
    const tokens = &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 4 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .String = "c" },
        .{ .I32 = 3 },
        .{ .String = "TESTING" },
        .{ .I32 = 4 },
        .{ .StructEnd = {} },
    };
    const expected = T{ .a = 1, .b = 2, .c = 3 };

    try t.run(deserialize, Visitor, tokens, expected);
}

test "deserialize - struct, attributes (rename)" {
    const T = struct {
        a: i32,
        b: i32,
        c: i32,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .a = .{ .rename = "A" },
                .b = .{ .rename = "B" },
                .c = .{ .rename = "C" },
            };
        };
    };
    const tokens = &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 3 } },
        .{ .String = "A" },
        .{ .I32 = 1 },
        .{ .String = "B" },
        .{ .I32 = 2 },
        .{ .String = "C" },
        .{ .I32 = 3 },
        .{ .StructEnd = {} },
    };
    const expected = T{ .a = 1, .b = 2, .c = 3 };

    try t.run(deserialize, Visitor, tokens, expected);
}

test "deserialize - struct, attributes (skip)" {
    const T = struct {
        a: i32 = 1,
        b: i32,
        c: i32 = 3,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .a = .{ .skip = true },
                .c = .{ .skip = true },
            };
        };
    };
    const tokens = &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 1 } },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .StructEnd = {} },
    };
    const expected = T{ .a = 1, .b = 2, .c = 3 };

    try t.run(deserialize, Visitor, tokens, expected);
}
