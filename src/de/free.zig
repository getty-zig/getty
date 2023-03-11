const std = @import("std");

const attributes = @import("../attributes.zig");
const blocks = @import("blocks.zig");
const find_db = @import("find.zig").find_db;

/// Frees resources allocated by Getty during deserialization.
///
/// `free` assumes that all pointers passed to it are heap-allocated and
/// will therefore attempt to free them. So be sure not to pass in any
/// pointers pointing to values on the stack.
pub fn free(
    /// A memory allocator.
    allocator: std.mem.Allocator,
    /// A `getty.Deserializer` interface type.
    comptime Deserializer: type,
    /// A value to deallocate.
    value: anytype,
) void {
    const T = @TypeOf(value);

    const db = comptime blk: {
        var db = find_db(T, Deserializer);

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
        db.free(allocator, Deserializer, value);
    }
}
