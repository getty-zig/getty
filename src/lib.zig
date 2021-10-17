//! A serialization and deserialization framework for the Zig programming
//! language.
//!
//! At its core, Getty is composed of two things: a data model (a set of
//! supported types) and data format interfaces (specifications of how to
//! convert between data and format). Together, these components enable any
//! supported data type to be serialized into any conforming data format, and
//! likewise any conforming data format to be deserialized into any data type.
//!
//! By leveraging the powerful compile-time features of Zig, Getty is able to
//! avoid the inherent runtime overhead of more traditional serialization
//! methods such as reflection. Additionally, `comptime` enables all supported
//! data types to automatically become serializable and deserializable.

const std = @import("std");

/// Serialization framework
pub usingnamespace @import("ser.zig");

/// Deserialization framework
pub usingnamespace @import("de.zig");

pub fn free(allocator: *std.mem.Allocator, value: anytype) void {
    const T = @TypeOf(value);
    const name = @typeName(T);

    switch (@typeInfo(T)) {
        .Bool, .Float, .ComptimeFloat, .Int, .ComptimeInt, .Enum, .EnumLiteral, .Null, .Void => {},
        .Array => for (value) |v| free(allocator, v),
        .Optional => if (value) |v| free(allocator, v),
        .Pointer => |info| switch (info.size) {
            .One => {
                free(allocator, value.*);
                allocator.destroy(value);
            },
            .Slice => {
                for (value) |v| free(allocator, v);
                allocator.free(value);
            },
            else => unreachable,
        },
        .Union => |info| {
            if (info.tag_type) |Tag| {
                inline for (info.fields) |field| {
                    if (value == @field(Tag, field.name)) {
                        free(allocator, @field(value, field.name));
                        break;
                    }
                }
            } else unreachable;
        },
        .Struct => |info| {
            if (comptime std.mem.startsWith(u8, name, "std.array_list.ArrayListAlignedUnmanaged")) {
                for (value.items) |v| free(allocator, v);

                // A copy is needed since the `deinit` method for unmanaged
                // ArrayLists takes `*Self` instead of `Self`.
                var copy = value;
                copy.deinit(allocator);
            } else if (comptime std.mem.startsWith(u8, name, "std.array_list.ArrayList")) {
                for (value.items) |v| free(allocator, v);
                value.deinit();
            } else {
                inline for (info.fields) |field| {
                    if (!field.is_comptime) free(allocator, @field(value, field.name));
                }
            }
        },
        else => unreachable,
    }
}

test {
    @import("std").testing.refAllDecls(@This());
}
