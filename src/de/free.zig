const std = @import("std");

const attributes = @import("../attributes.zig");
const blocks = @import("blocks.zig");
const find_db = @import("find.zig").find_db;

/// Frees `v` using an allocator `ally` according to the deserialization blocks
/// specified in the `getty.Deserializer` type `D`.
///
/// `free` is intended to be used for freeing values deserialized by Getty. `v`
/// must be a fully deserialized value. Attempts to free partially deserialized
/// values will result in undefined behavior.
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
