const std = @import("std");
const test_ally = std.testing.allocator;

const getty_free = @import("../free.zig").free;
const HashMapVisitor = @import("../impls/visitor/hash_map.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    const is_hash_map = comptime std.mem.startsWith(u8, @typeName(T), "hash_map");
    const is_array_hash_map = comptime std.mem.startsWith(u8, @typeName(T), "array_hash_map");

    return is_hash_map or is_array_hash_map;
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

    return try deserializer.deserializeMap(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return HashMapVisitor(T);
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
    const T = @TypeOf(value);
    const name = @typeName(T);

    const unmanaged = comptime std.mem.startsWith(
        u8,
        name,
        "hash_map.HashMapUnmanaged",
    ) or std.mem.startsWith(
        u8,
        name,
        "array_hash_map.ArrayHashMapUnmanaged",
    );

    var iterator = value.iterator();
    while (iterator.next()) |entry| {
        getty_free(ally, Deserializer, entry.key_ptr.*);
        getty_free(ally, Deserializer, entry.value_ptr.*);
    }

    var mut = value;
    if (unmanaged) {
        mut.deinit(ally);
    } else {
        mut.deinit();
    }
}

// TODO: Empty tests for ArrayHashMap variants are commented out due to an
//       issue in the compiler. The error you get is "TODO (LLVM): implement
//       const of pointer type '[TODO fix internal compiler bug regarding
//       dump]' (value.Value.Tag.comptime_field_ptr)".
test "deserialize - std.AutoHashMap, std.AutoArrayHashMap" {
    const tests = .{
        .{
            .name = "AutoHashMap - empty",
            .tokens = &.{
                .{ .Map = .{ .len = 0 } },
                .{ .MapEnd = {} },
            },
            .want = std.AutoHashMap(void, void).init(test_ally),
        },
        .{
            .name = "AutoHashMap - non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .Bool = true },
                .{ .I32 = 2 },
                .{ .Bool = false },
                .{ .I32 = 3 },
                .{ .Bool = true },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.AutoHashMap(i32, bool).init(test_ally);
                try want.put(1, true);
                try want.put(2, false);
                try want.put(3, true);
                break :blk want;
            },
        },
        .{
            .name = "AutoArrayHashMap - empty",
            .tokens = &.{
                .{ .Map = .{ .len = 0 } },
                .{ .MapEnd = {} },
            },
            .want = std.AutoArrayHashMap(void, void).init(test_ally),
        },
        .{
            .name = "AutoArrayHashMap - non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .Bool = true },
                .{ .I32 = 2 },
                .{ .Bool = false },
                .{ .I32 = 3 },
                .{ .Bool = true },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.AutoArrayHashMap(i32, bool).init(test_ally);
                try want.put(1, true);
                try want.put(2, false);
                try want.put(3, true);
                break :blk want;
            },
        },
        //.{
        //.name = "AutoHashMapUnmanaged - empty",
        //.tokens = &.{
        //.{ .Map = .{ .len = 0 } },
        //.{ .MapEnd = {} },
        //},
        //.want = std.AutoHashMapUnmanaged(void, void){},
        //},
        .{
            .name = "AutoHashMapUnmanaged - non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .Bool = true },
                .{ .I32 = 2 },
                .{ .Bool = false },
                .{ .I32 = 3 },
                .{ .Bool = true },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.AutoHashMapUnmanaged(i32, bool){};
                try want.put(test_ally, 1, true);
                try want.put(test_ally, 2, false);
                try want.put(test_ally, 3, true);
                break :blk want;
            },
        },
        //.{
        //.name = "AutoArrayHashMapUnmanaged - empty",
        //.tokens = &.{
        //.{ .Map = .{ .len = 0 } },
        //.{ .MapEnd = {} },
        //},
        //.want = std.AutoArrayHashMapUnmanaged(void, void){},
        //},
        .{
            .name = "AutoArrayHashMapUnmanaged - non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .Bool = true },
                .{ .I32 = 2 },
                .{ .Bool = false },
                .{ .I32 = 3 },
                .{ .Bool = true },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.AutoArrayHashMapUnmanaged(i32, bool){};
                try want.put(test_ally, 1, true);
                try want.put(test_ally, 2, false);
                try want.put(test_ally, 3, true);
                break :blk want;
            },
        },
    };

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        defer free(test_ally, Deserializer, t.want);

        const Want = @TypeOf(t.want);
        var got = try testing.deserialize(test_ally, t.name, Self, Want, t.tokens);
        defer free(test_ally, Deserializer, got);

        try testing.expectEqual(t.name, t.want.count(), got.count());

        var it = t.want.iterator();
        while (it.next()) |kv| {
            try testing.expectEqual(t.name, t.want.get(kv.key_ptr.*).?, got.get(kv.key_ptr.*).?);
        }
    }
}

test "deserialize - std.StringHashMap, std.StringArrayHashMap" {
    const tests = .{
        .{
            .name = "StringHashMap - empty",
            .tokens = &.{
                .{ .Map = .{ .len = 0 } },
                .{ .MapEnd = {} },
            },
            .want = std.StringHashMap(void).init(test_ally),
        },
        .{
            .name = "StringHashMap - non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .String = "one" },
                .{ .Bool = true },
                .{ .String = "two" },
                .{ .Bool = false },
                .{ .String = "three" },
                .{ .Bool = true },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.StringHashMap(bool).init(test_ally);
                try want.put("one", true);
                try want.put("two", false);
                try want.put("three", true);
                break :blk want;
            },
        },
        .{
            .name = "StringArrayHashMap - empty",
            .tokens = &.{
                .{ .Map = .{ .len = 0 } },
                .{ .MapEnd = {} },
            },
            .want = std.StringArrayHashMap(void).init(test_ally),
        },
        .{
            .name = "StringArrayHashMap - non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .String = "one" },
                .{ .Bool = true },
                .{ .String = "two" },
                .{ .Bool = false },
                .{ .String = "three" },
                .{ .Bool = true },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.StringArrayHashMap(bool).init(test_ally);
                try want.put("one", true);
                try want.put("two", false);
                try want.put("three", true);
                break :blk want;
            },
        },
    };

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        var want = t.want;
        defer want.deinit();

        const Want = @TypeOf(t.want);
        var got = try testing.deserialize(test_ally, t.name, Self, Want, t.tokens);
        defer free(test_ally, Deserializer, got);

        try testing.expectEqual(t.name, t.want.count(), got.count());

        var it = t.want.iterator();
        while (it.next()) |kv| {
            try testing.expectEqual(t.name, t.want.get(kv.key_ptr.*).?, got.get(kv.key_ptr.*).?);
        }
    }
}

test "deserialize - std.StringHashMapUnmanaged, std.StringArrayHashMapUnmanaged" {
    const tests = .{
        .{
            .name = "StringHashMapUnmanaged - non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .String = "one" },
                .{ .Bool = true },
                .{ .String = "two" },
                .{ .Bool = false },
                .{ .String = "three" },
                .{ .Bool = true },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.StringHashMapUnmanaged(bool){};
                try want.put(test_ally, "one", true);
                try want.put(test_ally, "two", false);
                try want.put(test_ally, "three", true);
                break :blk want;
            },
        },
        .{
            .name = "StringArrayHashMapUnmanaged - non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .String = "one" },
                .{ .Bool = true },
                .{ .String = "two" },
                .{ .Bool = false },
                .{ .String = "three" },
                .{ .Bool = true },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.StringArrayHashMapUnmanaged(bool){};
                try want.put(test_ally, "one", true);
                try want.put(test_ally, "two", false);
                try want.put(test_ally, "three", true);
                break :blk want;
            },
        },
    };

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        var want = t.want;
        defer want.deinit(test_ally);

        const Want = @TypeOf(t.want);
        var got = try testing.deserialize(test_ally, t.name, Self, Want, t.tokens);
        defer free(test_ally, Deserializer, got);

        try testing.expectEqual(t.name, t.want.count(), got.count());

        var it = t.want.iterator();
        while (it.next()) |kv| {
            try testing.expectEqual(t.name, t.want.get(kv.key_ptr.*).?, got.get(kv.key_ptr.*).?);
        }
    }
}
