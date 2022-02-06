//! Deserialization framework.
//!
//! Visually, deserialization within Getty can be represented like so:
//!
//!                Data Format
//!
//!                     ↓          ←─────────────────────┐
//!                                                      │
//!              Getty Data Model                        │
//!                                                      │
//!                     ↓          ←──────┐              │
//!                                       │              │
//!                  Zig data             │              │
//!                                       │              │
//!                                       │
//!                                       │     `getty.Deserializer`
//!                                       │
//!
//!                            `getty.De` + `getty.de.Visitor`

const std = @import("std");

const getty = @import("lib.zig");

/// Deserializer interface
pub usingnamespace @import("de/interface/deserializer.zig");

pub const de = struct {
    pub const default_with = .{
        // std
        @import("de/with/array_list.zig"),
        @import("de/with/hash_map.zig"),
        @import("de/with/linked_list.zig"),
        @import("de/with/tail_queue.zig"),

        // primitives
        @import("de/with/array.zig"),
        @import("de/with/bool.zig"),
        @import("de/with/enum.zig"),
        @import("de/with/float.zig"),
        @import("de/with/int.zig"),
        @import("de/with/optional.zig"),
        @import("de/with/pointer.zig"),
        @import("de/with/slice.zig"),
        @import("de/with/struct.zig"),
        @import("de/with/tuple.zig"),
        @import("de/with/void.zig"),
    };

    /// Generic error set for `getty.De` implementations.
    pub const Error = std.mem.Allocator.Error || error{
        DuplicateField,
        InvalidLength,
        InvalidType,
        InvalidValue,
        MissingField,
        UnknownField,
        UnknownVariant,
        Unsupported,
    };

    pub usingnamespace @import("de/interface/map.zig");
    pub usingnamespace @import("de/interface/seed.zig");
    pub usingnamespace @import("de/interface/seq.zig");
    pub usingnamespace @import("de/interface/visitor.zig");

    pub usingnamespace @import("de/impl/seed/default.zig");

    /// Frees resources allocated during deserialization.
    pub fn free(allocator: std.mem.Allocator, value: anytype) void {
        const T = @TypeOf(value);
        const name = @typeName(T);

        switch (@typeInfo(T)) {
            .Bool, .Float, .ComptimeFloat, .Int, .ComptimeInt, .Enum, .EnumLiteral, .Null, .Void => {},
            .Array => for (value) |v| free(allocator, v),
            .Optional => if (value) |v| free(allocator, v),
            .Pointer => |info| switch (comptime std.meta.trait.isZigString(T)) {
                true => allocator.free(value),
                false => switch (info.size) {
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
                    var mut = value;
                    mut.deinit(allocator);
                } else if (comptime std.mem.startsWith(u8, name, "std.array_list.ArrayList")) {
                    for (value.items) |v| free(allocator, v);
                    value.deinit();
                } else if (comptime std.mem.startsWith(u8, name, "std.hash_map.HashMapUnmanaged")) {
                    var iterator = value.iterator();
                    while (iterator.next()) |entry| {
                        free(allocator, entry.key_ptr.*);
                        free(allocator, entry.value_ptr.*);
                    }
                    var mut = value;
                    mut.deinit(allocator);
                } else if (comptime std.mem.startsWith(u8, name, "std.hash_map.HashMap")) {
                    var iterator = value.iterator();
                    while (iterator.next()) |entry| {
                        free(allocator, entry.key_ptr.*);
                        free(allocator, entry.value_ptr.*);
                    }
                    var mut = value;
                    mut.deinit();
                } else if (comptime std.mem.startsWith(u8, name, "std.linked_list")) {
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
};

pub fn With(comptime Deserializer: type, comptime T: type) type {
    comptime {
        getty.concepts.@"getty.Deserializer"(Deserializer);

        inline for (Deserializer.with) |W| {
            if (W.is(T)) {
                return W;
            }
        }

        @compileError("type ` " ++ @typeName(T) ++ "` is not supported");
    }
}

pub fn deserialize(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype) blk: {
    const D = @TypeOf(deserializer);

    getty.concepts.@"getty.Deserializer"(D);

    break :blk D.Error!T;
} {
    const W = With(@TypeOf(deserializer), T);
    var v = W.visitor(allocator, T);

    return try _deserialize(T, deserializer, v.visitor());
}

fn _deserialize(comptime T: type, deserializer: anytype, visitor: anytype) blk: {
    const D = @TypeOf(deserializer);
    const V = @TypeOf(visitor);

    getty.concepts.@"getty.Deserializer"(D);
    getty.concepts.@"getty.de.Visitor"(V);

    break :blk D.Error!V.Value;
} {
    const W = With(@TypeOf(deserializer), T);

    return try W.deserialize(T, deserializer, visitor);
}
