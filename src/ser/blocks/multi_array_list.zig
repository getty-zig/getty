const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "multi_array_list");
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = ally;

    var s = try serializer.serializeSeq(value.len);
    const seq = s.seq();

    for (0..value.len) |i| {
        try seq.serializeElement(value.get(i));
    }

    return try seq.end();
}

test "serialize - multi array list" {
    const Element = struct {
        x: i32,
        y: i32,
    };
    const List = std.MultiArrayList(Element);

    var list = List{};
    defer list.deinit(std.testing.allocator);

    try t.run(null, serialize, list, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    try list.append(std.testing.allocator, .{
        .x = 1,
        .y = 2,
    });
    try list.append(std.testing.allocator, .{
        .x = 3,
        .y = 4,
    });
    try list.append(std.testing.allocator, .{
        .x = 5,
        .y = 6,
    });

    try t.run(null, serialize, list, &.{
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
    });
}
