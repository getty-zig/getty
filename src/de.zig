//! Deserialization framework.
//!
//! Visually, deserialization in Getty can be represented like so:
//!
//!                  Zig data
//!
//!                     ▲          <-----------------------
//!                     |                                 |
//!                                                       |
//!              Getty Data Model                         |
//!                                                       |
//!                     ▲          <-------               |
//!                     |                 |               |
//!                                       |               |
//!                Data Format            |               |
//!                                       |               |
//!                                       |
//!                                       |      Deserialization Block
//!                                       |
//!
//!                               `getty.Deserializer`
//!
//! Data Model
//! ==========
//!
//! The Getty Data Model (GDM) is the set of types supported by Getty. The
//! types within the GDM are purely conceptual; they aren't actual Zig types.
//! For example, there is no `i32` or `u64` in the GDM. Instead, they are both
//! considered to be the type: integer.
//!
//! By maintaining a data model, Getty establishes a generic baseline from
//! which deserializers can operate. This often simplifies the job of a
//! deserializer significantly. For example, Zig considers `struct { x: i32 }`
//! and `struct { y: bool }` to be different types. However, in Getty they are
//! both considered to be the same type: struct. This means that if a
//! deserializer knows how to deserialize into a struct (as defined by the
//! GDM), then it will be able to deserialize into `struct { x: i32 }` values,
//! `struct { y: bool }` values, and values of any other struct type that is
//! composed of data types supported by Getty.
//!
//! The deserialization GDM consists of the following types:
//!
//!   1. Boolean
//!   2. Enum
//!   3. Float
//!   4. Integer
//!   5. Map
//!   6. Optional
//!   7. Sequence
//!   8. String
//!   9. Struct
//!   10. Void
//!
//! Deserializers
//! =============
//!
//! A deserializer is an implementation of the `getty.Deserializer` interface.
//! They define the conversion process between an input data format (e.g.,
//! JSON, YAML) and Getty's data model. For example, a JSON deserializer would
//! be responsible for converting JSON maps into Getty maps.
//!
//! Deserialization Blocks
//! ======================
//!
//! Deserialization Blocks (DB) make up the core of custom deserialization in
//! Getty. DBs define how to deserialize into values of one or more types.
//!
//! A DB is a struct namespace containing three functions:
//!
//!   1. fn is(comptime T: type) bool
//!   2. fn deserialize(comptime T: type, deserializer: anytype, visitor: anytype) @TypeOf(deserializer).Error!@TypeOf(visitor).Value
//!   3. fn visitor(allocator: ?std.mem.Allocator, comptime T: type) ...
//!
//! The `is` function specifies which types are deserializable by the DB. The
//! `deserialize` defines how to deserialize the input data format into Getty's
//! data model. Finally, the `visitor` function returns an instance of an
//! implementation of the `getty.de.Visitor` interface, which Getty will use to
//! produce an actual Zig value.
//!
//! For example, the following shows a DB for booleans. With it, you can
//! deserialize into a `bool` from a JSON boolean or a JSON integer:
//!
//! ```zig
//! const bool_db = struct {
//!     pub fn is(comptime T: type) bool {
//!         return T == bool;
//!     }
//!
//!     pub fn deserialize(comptime _: anytype, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
//!         return try deserializer.deserializeBool(v);
//!     }
//!
//!     pub fn visitor(_: ?std.mem.Allocator, comptime _: type) Visitor {
//!         return .{};
//!     }
//!
//!     const Visitor = struct {
//!         pub usingnamespace getty.de.Visitor(
//!             @This(),
//!             bool,
//!             visitBool,
//!             undefined,
//!             undefined,
//!             visitInt,
//!             undefined,
//!             undefined,
//!             undefined,
//!             undefined,
//!             undefined,
//!             undefined,
//!         );
//!
//!         pub fn visitBool(_: @This(), comptime _: type, input: bool) !bool {
//!             return input;
//!         }
//!
//!         pub fn visitInt(_: @This(), comptime _: type, input: anytype) !bool {
//!             return input > 0;
//!         }
//!     };
//! };
//! ```
//!
//! Deserialization Tuples
//! ======================
//!
//! DBs can be grouped up into a tuple, known as a Deserialization Tuple (DT).
//!
//! Getty provides its own DT for various Zig data types, but users and
//! deserializers can provide their own through the `getty.Deserializer`
//! interface.

const getty = @import("lib.zig");
const std = @import("std");

/// Deserializer interface.
pub usingnamespace @import("de/interfaces/deserializer.zig");

/// Namespace for deserialization-specific types and functions.
pub const de = struct {
    /// Generic error set for `getty.de.Visitor` implementations.
    pub const Error = std.mem.Allocator.Error || error{
        DuplicateField,
        InvalidLength,
        InvalidType,
        InvalidValue,
        MissingField,
        MissingVariant,
        UnknownField,
        UnknownVariant,
        Unsupported,
    };

    /// Map access and deserialization interface.
    pub usingnamespace @import("de/interfaces/map.zig");

    /// Deserialization seed interface.
    pub usingnamespace @import("de/interfaces/seed.zig");

    /// Sequence access and deserialization interface.
    pub usingnamespace @import("de/interfaces/seq.zig");

    /// Union access and deserialization interface.
    pub usingnamespace @import("de/interfaces/union_access.zig");

    /// Variant access and deserialization interface.
    pub usingnamespace @import("de/interfaces/variant_access.zig");

    /// Visitor interface.
    pub usingnamespace @import("de/interfaces/visitor.zig");

    /// Default deserialization seed implementation.
    pub usingnamespace @import("de/impls/seed/default.zig");

    /// Frees resources allocated during Getty deserialization.
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
            .Union => |info| if (info.tag_type) |Tag| {
                inline for (info.fields) |field| {
                    if (value == @field(Tag, field.name)) {
                        free(allocator, @field(value, field.name));
                        break;
                    }
                }
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

    /// Returns the highest priority Deserialization Block for a type given a
    /// deserializer type.
    pub fn find_db(comptime Deserializer: type, comptime T: type) type {
        comptime {
            getty.concepts.@"getty.Deserializer"(Deserializer);

            inline for (Deserializer.dt) |db| {
                if (db.is(T)) {
                    return db;
                }
            }

            @compileError("type ` " ++ @typeName(T) ++ "` is not supported");
        }
    }
};

/// The default Deserialization Tuple.
///
/// If a user or deserializer DT is provided, the default DT is appended to the
/// end, thereby taking the lowest priority.
pub const default_dt = .{
    // std
    @import("de/blocks/array_list.zig"),
    @import("de/blocks/hash_map.zig"),
    @import("de/blocks/linked_list.zig"),
    @import("de/blocks/tail_queue.zig"),

    // primitives
    @import("de/blocks/array.zig"),
    @import("de/blocks/bool.zig"),
    @import("de/blocks/enum.zig"),
    @import("de/blocks/float.zig"),
    @import("de/blocks/int.zig"),
    @import("de/blocks/optional.zig"),
    @import("de/blocks/pointer.zig"),
    @import("de/blocks/slice.zig"),
    @import("de/blocks/struct.zig"),
    @import("de/blocks/tuple.zig"),
    @import("de/blocks/union.zig"),
    @import("de/blocks/void.zig"),
};

/// Deserializes a value from the given Getty deserializer.
pub fn deserialize(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype) blk: {
    const D = @TypeOf(deserializer);

    getty.concepts.@"getty.Deserializer"(D);

    break :blk D.Error!T;
} {
    const db = de.find_db(@TypeOf(deserializer), T);
    var v = db.Visitor(T){};

    return try _deserialize(allocator, T, deserializer, v.visitor());
}

fn _deserialize(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype, visitor: anytype) blk: {
    const D = @TypeOf(deserializer);
    const V = @TypeOf(visitor);

    getty.concepts.@"getty.Deserializer"(D);
    getty.concepts.@"getty.de.Visitor"(V);

    break :blk D.Error!V.Value;
} {
    const db = de.find_db(@TypeOf(deserializer), T);

    return try db.deserialize(allocator, T, deserializer, visitor);
}
