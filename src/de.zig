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

const getty = @import("getty");

const ArrayVisitor = @import("de/impl/visitor/array.zig").Visitor;
const ArrayListVisitor = @import("de/impl/visitor/array_list.zig").Visitor;
const BoolVisitor = @import("de/impl/visitor/bool.zig");
const EnumVisitor = @import("de/impl/visitor/enum.zig").Visitor;
const FloatVisitor = @import("de/impl/visitor/float.zig").Visitor;
const HashMapVisitor = @import("de/impl/visitor/hash_map.zig").Visitor;
const IntVisitor = @import("de/impl/visitor/int.zig").Visitor;
const OptionalVisitor = @import("de/impl/visitor/optional.zig").Visitor;
const LinkedListVisitor = @import("de/impl/visitor/linked_list.zig").Visitor;
const PointerVisitor = @import("de/impl/visitor/pointer.zig").Visitor;
const SliceVisitor = @import("de/impl/visitor/slice.zig").Visitor;
const StructVisitor = @import("de/impl/visitor/struct.zig").Visitor;
const TailQueueVisitor = @import("de/impl/visitor/tail_queue.zig").Visitor;
const TupleVisitor = @import("de/impl/visitor/tuple.zig").Visitor;
const VoidVisitor = @import("de/impl/visitor/void.zig");

const BoolDe = @import("de/impl/de/bool.zig").De;
const EnumDe = @import("de/impl/de/enum.zig").De;
const FloatDe = @import("de/impl/de/float.zig").De;
const IntDe = @import("de/impl/de/int.zig").De;
const MapDe = @import("de/impl/de/map.zig").De;
const OptionalDe = @import("de/impl/de/optional.zig").De;
const SequenceDe = @import("de/impl/de/sequence.zig").De;
const StringDe = @import("de/impl/de/string.zig").De;
const StructDe = @import("de/impl/de/struct.zig").De;
const VoidDe = @import("de/impl/de/void.zig").De;

/// Deserializer interface
pub usingnamespace @import("de/interface/deserializer.zig");

/// `De` interface
pub usingnamespace @import("de/interface/de.zig");

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

    pub usingnamespace @import("de/interface/seed.zig");
    pub usingnamespace @import("de/interface/visitor.zig");
    pub usingnamespace @import("de/interface/access/map.zig");
    pub usingnamespace @import("de/interface/access/sequence.zig");

    pub usingnamespace @import("de/impl/seed/default.zig");

    /// Frees resources allocated during deserialization.
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

    pub const concepts = struct {
        pub fn @"getty.de.Visitor"(comptime T: type) void {
            const err = "expected `getty.de.Visitor` interface value, found `" ++ @typeName(T) ++ "`";

            comptime {
                // Invariants
                if (!std.meta.trait.isContainer(T)) {
                    @compileError(err);
                }

                const has_name = std.mem.startsWith(u8, @typeName(T), "getty.de.Visitor");
                const has_field = std.meta.trait.hasField("context")(T);
                const has_decl = @hasDecl(T, "Value");
                const has_funcs = std.meta.trait.hasFunctions(T, .{
                    "visitBool",
                    "visitEnum",
                    "visitFloat",
                    "visitInt",
                    "visitMap",
                    "visitNull",
                    "visitSequence",
                    "visitSome",
                    "visitString",
                    "visitVoid",
                });

                if (!(has_name and has_field and has_decl and has_funcs)) {
                    @compileError(err);
                }
            }
        }
    };
};

/// Performs deserialization using a provided serializer and `de`.
pub fn deserializeWith(
    allocator: ?*std.mem.Allocator,
    comptime T: type,
    deserializer: anytype,
    d: anytype,
) @TypeOf(deserializer).Error!T {
    return try d.deserialize(allocator, T, deserializer);
}

/// Performs deserialization using a provided serializer and a default `de`.
pub fn deserialize(
    allocator: ?*std.mem.Allocator,
    comptime T: type,
    deserializer: anytype,
) @TypeOf(deserializer).Error!T {
    var v = switch (@typeInfo(T)) {
        .Array => ArrayVisitor(T){},
        .Bool => BoolVisitor{},
        .Enum => EnumVisitor(T){},
        .Float, .ComptimeFloat => FloatVisitor(T){},
        .Int, .ComptimeInt => IntVisitor(T){},
        .Optional => OptionalVisitor(T){ .allocator = allocator },
        .Pointer => |info| switch (info.size) {
            .One => PointerVisitor(T){ .allocator = allocator.? },
            .Slice => SliceVisitor(T){ .allocator = allocator.? },
            else => @compileError("type ` " ++ @typeName(T) ++ "` is not supported"),
        },
        .Struct => |info| blk: {
            if (comptime std.mem.startsWith(u8, @typeName(T), "std.array_list")) {
                break :blk ArrayListVisitor(T){ .allocator = allocator.? };
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "std.hash_map")) {
                break :blk HashMapVisitor(T){ .allocator = allocator.? };
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "std.linked_list.SinglyLinkedList")) {
                break :blk LinkedListVisitor(T){ .allocator = allocator.? };
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "std.linked_list.TailQueue")) {
                break :blk TailQueueVisitor(T){ .allocator = allocator.? };
            } else switch (info.is_tuple) {
                true => break :blk TupleVisitor(T){},
                false => break :blk StructVisitor(T){ .allocator = allocator },
            }
        },
        .Void => VoidVisitor{},
        else => @compileError("type ` " ++ @typeName(T) ++ "` is not supported"),
    };

    return try _deserialize(allocator, T, deserializer, v.visitor());
}

fn _deserialize(
    allocator: ?*std.mem.Allocator,
    comptime T: type,
    deserializer: anytype,
    visitor: anytype,
) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
    const Visitor = @TypeOf(visitor);

    var d = switch (@typeInfo(T)) {
        .Array => SequenceDe(Visitor){ .visitor = visitor },
        .Bool => BoolDe(Visitor){ .visitor = visitor },
        .Enum => EnumDe(Visitor){ .visitor = visitor },
        .Float, .ComptimeFloat => FloatDe(Visitor){ .visitor = visitor },
        .Int, .ComptimeInt => IntDe(Visitor){ .visitor = visitor },
        .Optional => OptionalDe(Visitor){ .visitor = visitor },
        .Pointer => |info| switch (comptime std.meta.trait.isZigString(T)) {
            true => StringDe(Visitor){ .visitor = visitor },
            false => switch (info.size) {
                .One => return try _deserialize(allocator, std.meta.Child(T), deserializer, visitor),
                .Slice => SequenceDe(Visitor){ .visitor = visitor },
                else => unreachable, // UNREACHABLE: `deserialize` raises a compile error for this branch.
            },
        },
        .Struct => |info| blk: {
            if (comptime std.mem.startsWith(u8, @typeName(T), "std.array_list")) {
                break :blk SequenceDe(Visitor){ .visitor = visitor };
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "std.hash_map")) {
                break :blk MapDe(Visitor){ .visitor = visitor };
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "std.linked_list")) {
                break :blk SequenceDe(Visitor){ .visitor = visitor };
            } else switch (info.is_tuple) {
                true => break :blk SequenceDe(Visitor){ .visitor = visitor },
                false => break :blk StructDe(Visitor){ .visitor = visitor },
            }
        },
        .Void => VoidDe(Visitor){ .visitor = visitor },
        else => unreachable, // UNREACHABLE: `deserialize` raises a compile error for this branch.
    };

    return try deserializeWith(allocator, Visitor.Value, deserializer, d.de());
}
