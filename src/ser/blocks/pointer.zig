const std = @import("std");
const t = @import("getty/testing");

const ser = @import("../ser.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).Pointer;

    // Serialize array pointers as slices so that strings are handled properly.
    if (@typeInfo(info.child) == .Array) {
        return try ser.serialize(@as([]const std.meta.Elem(info.child), value), serializer);
    }

    return try ser.serialize(value.*, serializer);
}

test "serialize - pointer" {

    // one level of indirection
    {
        var ptr = try std.testing.allocator.create(i32);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = @as(i32, 1);

        try t.ser.run(serialize, ptr, &.{.{ .I32 = 1 }});
    }

    // two levels of indirection
    {
        var tmp = try std.testing.allocator.create(i32);
        defer std.testing.allocator.destroy(tmp);
        tmp.* = 2;

        var ptr = try std.testing.allocator.create(*i32);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = tmp;

        try t.ser.run(serialize, ptr, &.{.{ .I32 = 2 }});
    }

    // pointer to slice
    {
        var ptr = try std.testing.allocator.create([]const u8);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = "3";

        try t.ser.run(serialize, ptr, &.{.{ .String = "3" }});
    }
}
