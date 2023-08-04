const std = @import("std");

const getty_free = @import("../free.zig").free;
const StructVisitor = @import("../impls/visitor/struct.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

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
    ally: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeStruct(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return StructVisitor(T);
}

/// Frees resources allocated by Getty during deserialization.
pub fn free(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// A `getty.Deserializer` interface type.
    comptime Deserializer: type,
    /// A value to deallocate.
    value: anytype,
) void {
    const info = @typeInfo(@TypeOf(value)).Struct;

    inline for (info.fields) |field| {
        if (!field.is_comptime) {
            getty_free(ally, Deserializer, @field(value, field.name));
        }
    }
}

test "deserialize - struct" {
    const Empty = struct {};
    const NonEmpty = struct {
        a: i32,
        b: i32,
        c: i32,
    };

    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(Empty), .len = 0 } },
                .{ .StructEnd = {} },
            },
            .want = Empty{},
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(NonEmpty), .len = 3 } },
                .{ .String = "a" },
                .{ .I32 = 1 },
                .{ .String = "b" },
                .{ .I32 = 2 },
                .{ .String = "c" },
                .{ .I32 = 3 },
                .{ .StructEnd = {} },
            },
            .want = NonEmpty{ .a = 1, .b = 2, .c = 3 },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        try testing.expectEqual(t.name, t.want, got);
    }
}

test "deserialize - struct, attributes" {
    const IgnoreUnknownFields = struct {
        a: i32,
        b: i32,
        c: i32,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .Container = .{ .ignore_unknown_fields = true },
            };
        };
    };

    const Rename = struct {
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

    const Skip = struct {
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

    const Default = struct {
        a: i32,
        b: i32 = 2,
        c: i32,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .b = .{ .default = 20 },
                .c = .{ .default = 3 },
            };
        };
    };

    const tests = .{
        .{
            .name = "ignore_unknown_fields",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(IgnoreUnknownFields), .len = 4 } },
                .{ .String = "a" },
                .{ .I32 = 1 },
                .{ .String = "b" },
                .{ .I32 = 2 },
                .{ .String = "c" },
                .{ .I32 = 3 },
                .{ .String = "TESTING" },
                .{ .I32 = 4 },
                .{ .StructEnd = {} },
            },
            .want = IgnoreUnknownFields{ .a = 1, .b = 2, .c = 3 },
        },
        .{
            .name = "rename (success)",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(Rename), .len = 3 } },
                .{ .String = "A" },
                .{ .I32 = 1 },
                .{ .String = "B" },
                .{ .I32 = 2 },
                .{ .String = "C" },
                .{ .I32 = 3 },
                .{ .StructEnd = {} },
            },
            .want = Rename{ .a = 1, .b = 2, .c = 3 },
        },
        .{
            .name = "rename (fail)",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(Rename), .len = 3 } },
                .{ .String = "a" },
                .{ .I32 = 1 },
                .{ .String = "b" },
                .{ .I32 = 2 },
                .{ .String = "c" },
                .{ .I32 = 3 },
                .{ .StructEnd = {} },
            },
            .Want = Rename,
            .want_err = error.UnknownField,
        },
        .{
            .name = "skip (success, two fields omitted)",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(Skip), .len = 1 } },
                .{ .String = "b" },
                .{ .I32 = 2 },
                .{ .StructEnd = {} },
            },
            .want = Skip{ .a = 1, .b = 2, .c = 3 },
        },
        .{
            .name = "skip (success, zero fields omitted)",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(Skip), .len = 3 } },
                .{ .String = "a" },
                .{ .I32 = 1 },
                .{ .String = "b" },
                .{ .I32 = 2 },
                .{ .String = "c" },
                .{ .I32 = 3 },
                .{ .StructEnd = {} },
            },
            .want = Skip{ .a = 1, .b = 2, .c = 3 },
        },
        .{
            .name = "default (success)",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(Default), .len = 1 } },
                .{ .String = "a" },
                .{ .I32 = 1 },
                .{ .StructEnd = {} },
            },
            .want = Default{ .a = 1, .b = 20, .c = 3 },
        },
        .{
            .name = "default (ignored)",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(Default), .len = 2 } },
                .{ .String = "a" },
                .{ .I32 = 1 },
                .{ .String = "c" },
                .{ .I32 = 30 },
                .{ .StructEnd = {} },
            },
            .want = Default{ .a = 1, .b = 20, .c = 30 },
        },
    };

    inline for (tests) |t| {
        const Test = @TypeOf(t);

        if (@hasField(Test, "want_err")) {
            const Want = t.Want;

            try testing.expectError(
                t.name,
                t.want_err,
                testing.deserializeErr(std.testing.allocator, Self, Want, t.tokens),
            );
        } else {
            const Want = @TypeOf(t.want);

            const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
            try testing.expectEqual(t.name, t.want, got);
        }
    }
}
