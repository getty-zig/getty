const std = @import("std");
const Allocator = std.mem.Allocator;

const blocks = @import("../blocks.zig");
const find_db = @import("../find.zig").find_db;
const getty_free = @import("../free.zig").free;
const has_attributes = @import("../../attributes.zig").has_attributes;
const Ignored = @import("../impls/seed/ignored.zig").Ignored;
const PointerVisitor = @import("../impls/visitor/pointer.zig").Visitor;
const testing = @import("../testing.zig");
const VisitorInterface = @import("../interfaces/visitor.zig").Visitor;

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    ally: ?Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    if (comptime std.meta.trait.isZigString(T)) {
        return try deserializer.deserializeString(ally, visitor);
    }

    const Child = std.meta.Child(T);
    const db = comptime find_db(Child, @TypeOf(deserializer));

    if (comptime has_attributes(Child, db)) {
        switch (@typeInfo(Child)) {
            .Enum => return try blocks.Enum.deserialize(ally, Child, deserializer, visitor),
            .Struct => return try blocks.Struct.deserialize(ally, Child, deserializer, visitor),
            .Union => return try blocks.Union.deserialize(ally, Child, deserializer, visitor),
            else => unreachable, // UNREACHABLE: has_attributes guarantees that Child is an enum, struct or union.
        }
    }

    return try db.deserialize(ally, Child, deserializer, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return PointerVisitor(T);
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
    const info = @typeInfo(@TypeOf(value)).Pointer;

    comptime std.debug.assert(info.size == .One);

    // Trying to free `anyopaque` or `fn` values here triggers the errors in
    // the following issue: https://github.com/getty-zig/getty/issues/37.
    switch (@typeInfo(info.child)) {
        .Fn, .Opaque => {},
        else => {
            getty_free(ally, Deserializer, value.*);
            ally.destroy(value);
        },
    }
}

test "deserialize - pointer" {
    const EnumAB = enum {
        foo,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .rename = "FOO" },
            };
        };
    };
    const StructAB = struct {
        x: i32,
        y: i32,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .x = .{ .rename = "X" },
                .y = .{ .rename = "Y" },
            };
        };
    };
    const UnionAB = union(enum) {
        foo: i32,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .rename = "FOO" },
            };
        };
    };
    const UnionABUntagged = union(enum) {
        foo: i32,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .Container = .{ .tag = .untagged },
            };
        };
    };

    var int: i32 = 1;
    var eab = EnumAB.foo;
    var sab = StructAB{ .x = 1, .y = 2 };
    var uab = UnionAB{ .foo = 1 };
    var uab_untagged_1st = UnionABUntagged{ .foo = 123 };
    var uab_untagged_2nd = UnionABUntagged{ .bar = true };

    const tests = .{
        .{
            .name = "one level of indirection",
            .tokens = &.{.{ .I32 = 1 }},
            .want = @as(*i32, &int),
        },
        .{
            .name = "enum with AB",
            .tokens = &.{
                .{ .Enum = {} },
                .{ .String = "FOO" },
            },
            .want = @as(*EnumAB, &eab),
        },
        .{
            .name = "struct with AB",
            .tokens = &.{
                .{ .Struct = .{ .name = @typeName(StructAB), .len = 2 } },
                .{ .String = "X" },
                .{ .I32 = 1 },
                .{ .String = "Y" },
                .{ .I32 = 2 },
                .{ .StructEnd = {} },
            },
            .want = @as(*StructAB, &sab),
        },
        .{
            .name = "union with AB (rename)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "FOO" },
                .{ .I32 = 1 },
            },
            .want = @as(*UnionAB, &uab),
        },
        .{
            .name = "union with AB (untagged, 1st variant)",
            .tokens = &.{.{ .I32 = 123 }},
            .want = @as(*UnionABUntagged, &uab_untagged_1st),
        },
        .{
            .name = "union with AB (untagged, 2nd variant)",
            .tokens = &.{.{ .Bool = true }},
            .want = @as(*UnionABUntagged, &uab_untagged_2nd),
        },
    };

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        try testing.expectEqual(t.name, t.want.*, got.*);
    }
}

test "deserialize - pointer, string" {
    var no_sentinel = [3]u8{ 'a', 'b', 'c' };
    const no_sentinel_const = [3]u8{ 'a', 'b', 'c' };

    var sentinel = [3:0]u8{ 'a', 'b', 'c' };
    const sentinel_const = [3:0]u8{ 'a', 'b', 'c' };

    const tests = .{
        .{
            .name = "no sentinel (string)",
            .tokens = &.{.{ .String = "abc" }},
            .want = &no_sentinel,
        },
        .{
            .name = "no sentinel (sequence)",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            },
            .want = &no_sentinel,
        },
        .{
            .name = "no sentinel, const (string)",
            .tokens = &.{.{ .String = "abc" }},
            .want = &no_sentinel_const,
        },
        .{
            .name = "no sentinel, const (sequence)",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            },
            .want = &no_sentinel_const,
        },
        .{
            .name = "sentinel (string)",
            .tokens = &.{.{ .String = "abc" }},
            .want = &sentinel,
        },
        .{
            .name = "sentinel (sequence)",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            },
            .want = &sentinel,
        },
        .{
            .name = "sentinel, const (string)",
            .tokens = &.{.{ .String = "abc" }},
            .want = &sentinel_const,
        },
        .{
            .name = "sentinel, const (sequence)",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .U8 = 'a' },
                .{ .U8 = 'b' },
                .{ .U8 = 'c' },
                .{ .SeqEnd = {} },
            },
            .want = &sentinel_const,
        },
    };

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        try testing.expectEqualStrings(t.name, t.want, got);
    }
}

test "deserialize - pointer (recursive)" {
    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    const Want = **i32;
    const want: i32 = 1;

    const got = try testing.deserialize(std.testing.allocator, null, Self, Want, &.{.{ .I32 = 1 }});
    defer free(std.testing.allocator, Deserializer, got);

    try std.testing.expectEqual(Want, @TypeOf(got));
    try std.testing.expectEqual(*i32, @TypeOf(got.*));
    try std.testing.expectEqual(i32, @TypeOf(got.*.*));
    try std.testing.expectEqual(want, got.*.*);
}
