const std = @import("std");

const SegmentedListVisitor = @import("../impls/visitor/segmented_list.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "segmented_list.SegmentedList");
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// A memory allocator.
    ally: std.mem.Allocator,
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
    return SegmentedListVisitor(T);
}

test "deserialize - std.SegmentedList" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.SegmentedList(u32, 0){},
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 4 } },
                .{ .U32 = 4 },
                .{ .U32 = 2 },
                .{ .U32 = 1 },
                .{ .U32 = 8 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var list = std.SegmentedList(u32, 0){};
                try list.append(std.testing.allocator, 4);
                try list.append(std.testing.allocator, 2);
                try list.append(std.testing.allocator, 1);
                try list.append(std.testing.allocator, 8);
                break :blk list;
            },
        },
    };

    inline for (tests) |t| {
        defer {
            var mut = t.want;
            mut.deinit(std.testing.allocator);
        }

        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.len, result.value.len);

        for (0..t.want.len) |i| {
            try testing.expectEqual(t.name, t.want.at(i).*, result.value.at(i).*);
        }
    }
}
