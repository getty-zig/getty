const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
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
    const info = @typeInfo(@TypeOf(value)).Pointer;

    // Serialize array pointers as slices so that strings are handled properly.
    if (@typeInfo(info.child) == .Array) {
        const Slice = []const std.meta.Elem(info.child);
        return try getty_serialize(ally, @as(Slice, value), serializer);
    }

    return try getty_serialize(ally, value.*, serializer);
}

test "serialize - pointer" {
    // one level of indirection
    {
        var ptr = try std.testing.allocator.create(i32);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = @as(i32, 1);

        try t.run(null, serialize, ptr, &.{.{ .I32 = 1 }});
    }

    // two levels of indirection
    {
        var tmp = try std.testing.allocator.create(i32);
        defer std.testing.allocator.destroy(tmp);
        tmp.* = 2;

        var ptr = try std.testing.allocator.create(*i32);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = tmp;

        try t.run(null, serialize, ptr, &.{.{ .I32 = 2 }});
    }

    // pointer to slice
    {
        var ptr = try std.testing.allocator.create([]const u8);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = "3";

        try t.run(null, serialize, ptr, &.{.{ .String = "3" }});
    }
}
