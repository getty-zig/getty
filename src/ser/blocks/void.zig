//! `Void` is a _Serialization Block_ for void values.

const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return T == void;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Err!@TypeOf(serializer).Ok {
    _ = ally;
    _ = value;

    return try serializer.serializeVoid();
}

test "serialize - void" {
    try t.run(null, serialize, {}, &.{.{ .Void = {} }});
}
