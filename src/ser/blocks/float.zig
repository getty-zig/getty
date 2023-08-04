const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => true,
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

    return try serializer.serializeFloat(value);
}

test "serialize - float" {
    // comptime_float
    try t.run(null, serialize, 0.0, &.{.{ .ComptimeFloat = {} }});

    // float
    try t.run(null, serialize, @as(f16, 0), &.{.{ .F16 = 0 }});
    try t.run(null, serialize, @as(f32, 0), &.{.{ .F32 = 0 }});
    try t.run(null, serialize, @as(f64, 0), &.{.{ .F64 = 0 }});
    try t.run(null, serialize, @as(f128, 0), &.{.{ .F128 = 0 }});
}
