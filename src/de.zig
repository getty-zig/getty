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

    pub usingnamespace @import("de/interface/access/map.zig");
    pub usingnamespace @import("de/interface/access/sequence.zig");
    pub usingnamespace @import("de/interface/seed.zig");
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

pub fn deserialize(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype) blk: {
    getty.concepts.@"getty.Deserializer"(@TypeOf(deserializer));

    break :blk @TypeOf(deserializer).Error!T;
} {
    const Deserializer = @TypeOf(deserializer);

    var v = blk: {
        if (Deserializer.with) |with| {
            inline for (@typeInfo(with).Struct.decls) |decl| {
                const D = @field(with, decl.name);

                if (comptime D.is(T)) {
                    break :blk D.visitor(allocator, T);
                }
            }
        }

        inline for (@typeInfo(default_with).Struct.decls) |decl| {
            const D = @field(default_with, decl.name);

            if (comptime D.is(T)) {
                break :blk D.visitor(allocator, T);
            }
        }

        @compileError("type ` " ++ @typeName(T) ++ "` is not supported");
    };

    return try _deserialize(T, deserializer, v.visitor());
}

fn _deserialize(comptime T: type, deserializer: anytype, visitor: anytype) blk: {
    getty.concepts.@"getty.de.Visitor"(@TypeOf(visitor));

    break :blk @TypeOf(deserializer).Error!@TypeOf(visitor).Value;
} {
    const Deserializer = @TypeOf(deserializer);

    // Custom
    if (Deserializer.with) |with| {
        inline for (@typeInfo(with).Struct.decls) |decl| {
            const D = @field(with, decl.name);

            if (comptime D.is(T)) {
                return try D.deserialize(T, deserializer, visitor);
            }
        }
    }

    // Default
    inline for (@typeInfo(default_with).Struct.decls) |decl| {
        const D = @field(default_with, decl.name);

        if (comptime D.is(T)) {
            return try D.deserialize(T, deserializer, visitor);
        }
    }

    // UNREACHABLE: `deserialize` ensures that only supported types are passed
    // to this function.
    unreachable;
}

const default_with = struct {
    // Standard Library
    const array_lists = @import("de/with/array_list.zig");
    const hash_maps = @import("de/with/hash_map.zig");
    const linked_lists = @import("de/with/linked_list.zig");
    const tail_queues = @import("de/with/tail_queue.zig");

    // Primitives
    const arrays = @import("de/with/array.zig");
    const bools = @import("de/with/bool.zig");
    const enums = @import("de/with/enum.zig");
    const floats = @import("de/with/float.zig");
    const ints = @import("de/with/int.zig");
    const optionals = @import("de/with/optional.zig");
    const pointers = pointer_with;
    const slices = @import("de/with/slice.zig");
    const strings = @import("de/with/string.zig");
    const structs = @import("de/with/struct.zig");
    const tuples = @import("de/with/tuple.zig");
    const voids = @import("de/with/void.zig");
};

const pointer_with = struct {
    const Visitor = @import("de/impl/visitor/pointer.zig").Visitor;

    pub fn is(comptime T: type) bool {
        return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One and comptime !std.meta.trait.isZigString(T);
    }

    pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) Visitor(T) {
        return .{ .allocator = allocator.? };
    }

    pub fn deserialize(comptime T: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
        return try _deserialize(
            std.meta.Child(T),
            deserializer,
            v,
        );
    }
};
