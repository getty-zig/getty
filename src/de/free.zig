const std = @import("std");

const attributes = @import("../attributes.zig");
const blocks = @import("blocks.zig");
const find_db = @import("find.zig").find_db;

/// Frees `v` using an allocator `ally` according to the deserialization blocks
/// specified in the `getty.Deserializer` type `D`.
///
/// `free` is intended to be used only for freeing values fully deserialized by
/// Getty. Freeing partially deserialized values with `free` will result in
/// undefined behavior.
///
/// Getty's allocation model during deserialization is as follows:
///
///   - Deserialized pointer values returned by an access method (e.g.,
///     `nextKey`) will be freed upon failure and, where applicable [1], upon
///     success if the value's corresponding `isXAllocated` method (e.g.,
///     `isKeyAllocated`) returns true.
///
///   - Deserialized pointer values not returned by an access method will
///     always be freed upon failure and, where applicable [1], upon success.
///
///
/// 1. Generally speaking, "where applicable" means whenever a deserialized
///    value is not part of the final value returned to the end user. For
///    example, if a heap-allocated string is visited to produce an integer,
///    the string isn't part of the final, returned integer, and so it should
///    be freed even upon success.
pub fn free(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// A `getty.Deserializer` interface type.
    comptime D: type,
    /// A value to deallocate.
    v: anytype,
) void {
    const T = @TypeOf(v);

    const db = comptime blk: {
        var db = find_db(T, D);

        if (attributes.has_attributes(T, db)) {
            db = switch (@typeInfo(T)) {
                .Enum => blocks.Enum,
                .Struct => blocks.Struct,
                .Union => blocks.Union,
                else => unreachable, // UNREACHABLE: has_attributes guarantees that T is an enum, struct or union.
            };
        }

        break :blk db;
    };

    if (@hasDecl(db, "free")) {
        db.free(ally, D, v);
    }
}
