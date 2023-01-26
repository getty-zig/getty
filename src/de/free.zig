const std = @import("std");

/// Frees resources allocated by Getty during deserialization.
///
/// `free` assumes that all pointers passed to it are heap-allocated and
/// will therefore attempt to free them. So be sure not to pass in any
/// pointers pointing to values on the stack.
pub fn free(
    /// A memory allocator.
    allocator: std.mem.Allocator,
    /// A value to deallocate.
    value: anytype,
) void {
    const T = @TypeOf(value);
    const name = @typeName(T);

    switch (@typeInfo(T)) {
        .AnyFrame, .Bool, .Float, .ComptimeFloat, .Int, .ComptimeInt, .Enum, .EnumLiteral, .Fn, .Null, .Opaque, .Frame, .Void => {},
        .Array => for (value) |v| free(allocator, v),
        .Optional => if (value) |v| free(allocator, v),
        .Pointer => |info| switch (comptime std.meta.trait.isZigString(T)) {
            true => allocator.free(value),
            false => switch (info.size) {
                .One => {
                    // Trying to free `anyopaque` or `fn` values here
                    // triggers the errors in the following issue:
                    //
                    //   https://github.com/getty-zig/getty/issues/37.
                    switch (@typeInfo(info.child)) {
                        .Fn, .Opaque => return,
                        else => {
                            free(allocator, value.*);
                            allocator.destroy(value);
                        },
                    }
                },
                .Slice => {
                    for (value) |v| free(allocator, v);
                    allocator.free(value);
                },
                else => unreachable,
            },
        },
        .Union => |info| if (info.tag_type) |Tag| {
            inline for (info.fields) |field| {
                if (value == @field(Tag, field.name)) {
                    free(allocator, @field(value, field.name));
                    break;
                }
            }
        },
        .Struct => |info| {
            if (comptime std.mem.startsWith(u8, name, "array_list.ArrayListAlignedUnmanaged")) {
                for (value.items) |v| free(allocator, v);
                var mut = value;
                mut.deinit(allocator);
            } else if (comptime std.mem.startsWith(u8, name, "array_list.ArrayList")) {
                for (value.items) |v| free(allocator, v);
                value.deinit();
            } else if (T == std.BufMap) {
                var it = value.hash_map.iterator();
                while (it.next()) |entry| {
                    free(allocator, entry.key_ptr.*);
                    free(allocator, entry.value_ptr.*);
                }
                var mut = value;
                mut.hash_map.deinit();
            } else if (comptime std.mem.startsWith(u8, name, "hash_map.HashMapUnmanaged")) {
                var iterator = value.iterator();
                while (iterator.next()) |entry| {
                    free(allocator, entry.key_ptr.*);
                    free(allocator, entry.value_ptr.*);
                }
                var mut = value;
                mut.deinit(allocator);
            } else if (comptime std.mem.startsWith(u8, name, "hash_map.HashMap")) {
                var iterator = value.iterator();
                while (iterator.next()) |entry| {
                    free(allocator, entry.key_ptr.*);
                    free(allocator, entry.value_ptr.*);
                }
                var mut = value;
                mut.deinit();
            } else if (comptime std.mem.startsWith(u8, name, "linked_list")) {
                var iterator = value.first;
                while (iterator) |node| {
                    free(allocator, node.data);
                    iterator = node.next;
                    allocator.destroy(node);
                }
            } else {
                inline for (info.fields) |field| {
                    if (!field.is_comptime) free(allocator, @field(value, field.name));
                }
            }
        },
        else => unreachable,
    }
}
