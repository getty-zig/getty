const std = @import("std");

const getty_free = @import("../free.zig").free;
const MultiArrayListVisitor = @import("../impls/visitor/multi_array_list.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "multi_array_list");
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

    return try deserializer.deserializeSeq(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return MultiArrayListVisitor(T);
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
    defer {
        var mut = value;
        mut.deinit(ally);
    }

    for (0..value.len) |i| {
        getty_free(ally, Deserializer, value.get(i));
    }
}

test "deserialize - multi array list" {
    const Element = struct {
        x: i32,
        y: i32,
    };
    const List = std.MultiArrayList(Element);

    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = List{},
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                // 1st element
                .{ .Struct = .{ .name = @typeName(Element), .len = 2 } },
                .{ .String = "x" },
                .{ .I32 = 1 },
                .{ .String = "y" },
                .{ .I32 = 2 },
                .{ .StructEnd = {} },
                // 2nd element
                .{ .Struct = .{ .name = @typeName(Element), .len = 2 } },
                .{ .String = "x" },
                .{ .I32 = 3 },
                .{ .String = "y" },
                .{ .I32 = 4 },
                .{ .StructEnd = {} },
                // 3rd element
                .{ .Struct = .{ .name = @typeName(Element), .len = 2 } },
                .{ .String = "x" },
                .{ .I32 = 5 },
                .{ .String = "y" },
                .{ .I32 = 6 },
                .{ .StructEnd = {} },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = List{};
                want.append(std.testing.allocator, Element{ .x = 1, .y = 2 }) catch return error.UnexpectedTestError;
                want.append(std.testing.allocator, Element{ .x = 3, .y = 4 }) catch return error.UnexpectedTestError;
                want.append(std.testing.allocator, Element{ .x = 5, .y = 6 }) catch return error.UnexpectedTestError;
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        defer {
            var mut = t.want;
            mut.deinit(std.testing.allocator);
        }

        const got = try testing.deserialize(std.testing.allocator, t.name, Self, List, t.tokens);
        defer {
            var mut = got;
            mut.deinit(std.testing.allocator);
        }

        try testing.expectEqual(t.name, t.want.len, got.len);
        try testing.expectEqual(t.name, t.want.capacity, got.capacity);

        for (0..t.want.len) |i| {
            try testing.expectEqual(t.name, t.want.get(i), got.get(i));
        }
    }
}
