const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Int, .ComptimeInt => true,
        else => false,
    };
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

    return try serializer.serializeInt(value);
}

test "serialize - integer" {
    // comptime_int
    try t.run(null, serialize, 0, &.{.{ .ComptimeInt = {} }});

    // signed
    try t.run(null, serialize, @as(i8, 0), &.{.{ .I8 = 0 }});
    try t.run(null, serialize, @as(i16, 0), &.{.{ .I16 = 0 }});
    try t.run(null, serialize, @as(i32, 0), &.{.{ .I32 = 0 }});
    try t.run(null, serialize, @as(i64, 0), &.{.{ .I64 = 0 }});
    try t.run(null, serialize, @as(i128, 0), &.{.{ .I128 = 0 }});

    // unsigned
    try t.run(null, serialize, @as(u8, 0), &.{.{ .U8 = 0 }});
    try t.run(null, serialize, @as(u16, 0), &.{.{ .U16 = 0 }});
    try t.run(null, serialize, @as(u32, 0), &.{.{ .U32 = 0 }});
    try t.run(null, serialize, @as(u64, 0), &.{.{ .U64 = 0 }});
    try t.run(null, serialize, @as(u128, 0), &.{.{ .U128 = 0 }});
}
