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
        // Custom
        if (Deserializer.De != DefaultDe) {
            inline for (comptime std.meta.declarations(Deserializer.De)) |decl| {
                const D = @field(Deserializer.De, decl.name);

                if (comptime D.is(T)) {
                    break :blk D.visitor(allocator, T);
                }
            }
        }

        // Default
        inline for (comptime std.meta.declarations(DefaultDe)) |decl| {
            const D = @field(DefaultDe, decl.name);

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
    if (Deserializer.De != DefaultDe) {
        inline for (comptime std.meta.declarations(Deserializer.De)) |decl| {
            const D = @field(Deserializer.De, decl.name);

            if (comptime D.is(T)) {
                return try D.deserialize(T, deserializer, visitor);
            }
        }
    }

    // Default
    inline for (comptime std.meta.declarations(DefaultDe)) |decl| {
        const D = @field(DefaultDe, decl.name);

        if (comptime D.is(T)) {
            return try D.deserialize(T, deserializer, visitor);
        }
    }

    // UNREACHABLE: `deserialize` ensures that only supported types are passed
    // to this function.
    unreachable;
}

pub const DefaultDe = struct {
    // Primitives
    pub const arrays = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Array;
        }

        pub fn visitor(_: ?std.mem.Allocator, comptime T: type) ArrayVisitor(T) {
            return .{};
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeSequence(v);
        }
    };

    pub const bools = struct {
        pub fn is(comptime T: type) bool {
            return T == bool;
        }

        pub fn visitor(_: ?std.mem.Allocator, comptime _: type) BoolVisitor {
            return .{};
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeBool(v);
        }
    };

    pub const enums = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Enum;
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) EnumVisitor(T) {
            return .{ .allocator = allocator };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeEnum(v);
        }
    };

    pub const floats = struct {
        pub fn is(comptime T: type) bool {
            return switch (@typeInfo(T)) {
                .Float, .ComptimeFloat => true,
                else => false,
            };
        }

        pub fn visitor(_: ?std.mem.Allocator, comptime T: type) FloatVisitor(T) {
            return .{};
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeFloat(v);
        }
    };

    pub const ints = struct {
        pub fn is(comptime T: type) bool {
            return switch (@typeInfo(T)) {
                .Int, .ComptimeInt => true,
                else => false,
            };
        }

        pub fn visitor(_: ?std.mem.Allocator, comptime T: type) IntVisitor(T) {
            return .{};
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeInt(v);
        }
    };

    pub const one_pointers = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One and comptime !std.meta.trait.isZigString(T);
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) PointerVisitor(T) {
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

    pub const optionals = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Optional;
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) OptionalVisitor(T) {
            return .{ .allocator = allocator };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeOptional(v);
        }
    };

    pub const slices = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice and comptime !std.meta.trait.isZigString(T);
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) SliceVisitor(T) {
            return .{ .allocator = allocator.? };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeSequence(v);
        }
    };

    pub const string_ptrs = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One and comptime std.meta.trait.isZigString(T);
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) PointerVisitor(T) {
            return .{ .allocator = allocator.? };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeString(v);
        }
    };

    pub const string_slices = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice and comptime std.meta.trait.isZigString(T);
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) SliceVisitor(T) {
            return .{ .allocator = allocator.? };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeString(v);
        }
    };

    pub const tuples = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Struct and @typeInfo(T).Struct.is_tuple;
        }

        pub fn visitor(_: ?std.mem.Allocator, comptime T: type) TupleVisitor(T) {
            return .{};
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeSequence(v);
        }
    };

    pub const voids = struct {
        pub fn is(comptime T: type) bool {
            return T == void;
        }

        pub fn visitor(_: ?std.mem.Allocator, comptime _: type) VoidVisitor {
            return .{};
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeVoid(v);
        }
    };

    // std
    pub const array_lists = struct {
        pub fn is(comptime T: type) bool {
            return comptime std.mem.startsWith(u8, @typeName(T), "std.array_list");
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) ArrayListVisitor(T) {
            return .{ .allocator = allocator.? };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeSequence(v);
        }
    };

    pub const hash_maps = struct {
        pub fn is(comptime T: type) bool {
            return comptime std.mem.startsWith(u8, @typeName(T), "std.hash_map");
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) HashMapVisitor(T) {
            return .{ .allocator = allocator.? };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeMap(v);
        }
    };

    pub const linked_lists = struct {
        pub fn is(comptime T: type) bool {
            return comptime std.mem.startsWith(u8, @typeName(T), "std.linked_list.SinglyLinkedList");
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) LinkedListVisitor(T) {
            return .{ .allocator = allocator.? };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeSequence(v);
        }
    };

    pub const tail_queues = struct {
        pub fn is(comptime T: type) bool {
            return comptime std.mem.startsWith(u8, @typeName(T), "std.linked_list.TailQueue");
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) TailQueueVisitor(T) {
            return .{ .allocator = allocator.? };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeSequence(v);
        }
    };

    // struct
    pub const structs = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
        }

        pub fn visitor(allocator: ?std.mem.Allocator, comptime T: type) StructVisitor(T) {
            return .{ .allocator = allocator };
        }

        pub fn deserialize(comptime _: type, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
            return try deserializer.deserializeStruct(v);
        }
    };
};
