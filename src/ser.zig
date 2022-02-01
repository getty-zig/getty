//! Serialization framework.
//!
//! Visually, serialization within Getty can be represented like so:
//!
//!                  Zig data
//!
//!                     ↓          <------------------
//!                                                  |
//!              Getty Data Model                    |
//!                                                  |
//!                     ↓          <-------          |
//!                                       |          |
//!                Data Format            |          |
//!                                       |          |
//!                                       |
//!                                       |     `getty.Ser`
//!                                       |
//!
//!                               `getty.Serializer`
//!
//! # Data Model
//!
//! The Getty data model is the set of types supported by Getty. The types
//! within this set are purely conceptual; they aren't actual Zig types. For
//! example, there is no `i32` or `u64` in Getty's data model. Instead, they
//! are both considered to be the same type: integer.
//!
//! By maintaining a data model, Getty establishes a generic baseline from
//! which serializers can operate. This can often simplify the job of a
//! serializer significantly. For example, Zig considers `struct { x: i32 }`
//! and `struct { y: bool }` to be different types. However, in Getty they are
//! both considered to be the same type: struct. This means that if a
//! serializer supports struct (as defined by Getty) serialization, then by
//! definition it supports serialization for `struct { x: i32 }` values,
//! `struct { y: bool }` values, and values of any other struct type that is
//! composed of data types supported by Getty.
//!
//! # Serializers
//!
//! A serializer defines the conversion process between Getty's data model and
//! an output data format. For example, a JSON serializer would specify that
//! Getty strings should be serialized as `"<INSERT STRING HERE>"`.

const std = @import("std");

const getty = @import("lib.zig");

/// Serializer interface
pub usingnamespace @import("ser/interface/serializer.zig");

/// `ser` namespace
pub const ser = struct {
    /// Generic error set for `getty.Ser` implementations.
    pub const Error = std.mem.Allocator.Error || error{
        Unsupported,
    };

    pub usingnamespace @import("ser/interface/serialize/map.zig");
    pub usingnamespace @import("ser/interface/serialize/sequence.zig");
    pub usingnamespace @import("ser/interface/serialize/struct.zig");
    pub usingnamespace @import("ser/interface/serialize/tuple.zig");
};

pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
    const T = @TypeOf(value);
    const Serializer = @TypeOf(serializer);

    if (Serializer.Ser != DefaultSer) {
        inline for (std.meta.declarations(Serializer.Ser)) |decl| {
            const S = @field(Serializer.Ser, decl.name);

            if (comptime S.is(T)) {
                return try S.serialize(value, serializer);
            }
        }
    }

    inline for (std.meta.declarations(DefaultSer)) |decl| {
        const S = @field(DefaultSer, decl.name);

        if (comptime S.is(T)) {
            return try S.serialize(value, serializer);
        }
    }

    @compileError("type `" ++ @typeName(T) ++ "` is not supported");
}

pub const DefaultSer = struct {
    pub const Array = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Array;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            const seq = (try serializer.serializeSequence(value.len)).sequenceSerialize();
            for (value) |elem| {
                try seq.serializeElement(elem);
            }
            return try seq.end();
        }
    };

    pub const ArrayList = struct {
        pub fn is(comptime T: type) bool {
            return std.mem.startsWith(u8, @typeName(T), "std.array_list");
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try getty.serialize(value.items, serializer);
        }
    };

    pub const Bool = struct {
        pub fn is(comptime T: type) bool {
            return T == bool;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try serializer.serializeBool(value);
        }
    };

    pub const Enum = struct {
        pub fn is(comptime T: type) bool {
            return switch (@typeInfo(T)) {
                .Enum, .EnumLiteral => true,
                else => false,
            };
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try serializer.serializeEnum(value);
        }
    };

    pub const ErrorSet = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .ErrorSet;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try getty.serialize(@as([]const u8, @errorName(value)), serializer);
        }
    };

    pub const Float = struct {
        pub fn is(comptime T: type) bool {
            return switch (@typeInfo(T)) {
                .Float, .ComptimeFloat => true,
                else => false,
            };
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try serializer.serializeFloat(value);
        }
    };

    pub const HashMap = struct {
        pub fn is(comptime T: type) bool {
            return std.mem.startsWith(u8, @typeName(T), "std.hash_map");
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            const m = (try serializer.serializeMap(value.count())).mapSerialize();
            {
                var iterator = value.iterator();
                while (iterator.next()) |entry| {
                    try m.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
                }
            }
            return try m.end();
        }
    };

    pub const Int = struct {
        pub fn is(comptime T: type) bool {
            return switch (@typeInfo(T)) {
                .Int, .ComptimeInt => true,
                else => false,
            };
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try serializer.serializeInt(value);
        }
    };

    pub const LinkedList = struct {
        pub fn is(comptime T: type) bool {
            return std.mem.startsWith(u8, @typeName(T), "std.linked_list.SinglyLinkedList");
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            const seq = (try serializer.serializeSequence(value.len())).sequenceSerialize();
            {
                var iterator = value.first;
                while (iterator) |node| : (iterator = node.next) {
                    try seq.serializeElement(node.data);
                }
            }
            return try seq.end();
        }
    };

    pub const Null = struct {
        pub fn is(comptime T: type) bool {
            return T == @TypeOf(null);
        }

        pub fn serialize(_: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try serializer.serializeNull();
        }
    };

    pub const OnePointer = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            const info = @typeInfo(@TypeOf(value)).Pointer;

            // Serialize array pointers as slices so that strings are handled properly.
            if (@typeInfo(info.child) == .Array) {
                return try getty.serialize(@as([]const std.meta.Elem(info.child), value), serializer);
            }

            return try getty.serialize(value.*, serializer);
        }
    };

    pub const Optional = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Optional;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try if (value) |v| serializer.serializeSome(v) else serializer.serializeNull();
        }
    };

    pub const Slice = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice and comptime !std.meta.trait.isZigString(T);
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            const seq = (try serializer.serializeSequence(value.len)).sequenceSerialize();
            for (value) |elem| {
                try seq.serializeElement(elem);
            }
            return try seq.end();
        }
    };

    pub const String = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice and comptime std.meta.trait.isZigString(T);
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try serializer.serializeString(value);
        }
    };

    pub const TailQueue = struct {
        pub fn is(comptime T: type) bool {
            return std.mem.startsWith(u8, @typeName(T), "std.linked_list.TailQueue");
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            const seq = (try serializer.serializeSequence(value.len)).sequenceSerialize();
            {
                var iterator = value.first;
                while (iterator) |node| : (iterator = node.next) {
                    try seq.serializeElement(node.data);
                }
            }
            return try seq.end();
        }
    };

    pub const Tuple = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Struct and @typeInfo(T).Struct.is_tuple;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            const T = @TypeOf(value);

            const tuple = (try serializer.serializeTuple(std.meta.fields(T).len)).tupleSerialize();
            inline for (@typeInfo(T).Struct.fields) |field| {
                try tuple.serializeElement(@field(value, field.name));
            }
            return try tuple.end();
        }
    };

    pub const Union = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Union;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            switch (@typeInfo(@TypeOf(value))) {
                .Union => |info| if (info.tag_type) |_| {
                    inline for (info.fields) |field| {
                        if (std.mem.eql(u8, field.name, @tagName(value))) {
                            return try getty.serialize(@field(value, field.name), serializer);
                        }
                    }
                } else @compileError("expected tagged union, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
                else => @compileError("expected tagged union, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
            }
        }
    };

    pub const Vector = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Vector;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return switch (@typeInfo(@TypeOf(value))) {
                .Vector => |info| try getty.serialize(@as([info.len]info.child, value), serializer),
                else => @compileError("expected vector, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
            };
        }
    };

    pub const Void = struct {
        pub fn is(comptime T: type) bool {
            return T == void;
        }

        pub fn serialize(_: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            return try serializer.serializeVoid();
        }
    };

    // This should always be last.
    pub const Struct = struct {
        pub fn is(comptime T: type) bool {
            return @typeInfo(T) == .Struct;
        }

        pub fn serialize(value: anytype, serializer: anytype) Return(@TypeOf(serializer)) {
            const T = @TypeOf(value);
            const fields = std.meta.fields(T);

            const st = (try serializer.serializeStruct(@typeName(T), fields.len)).structSerialize();
            inline for (fields) |field| {
                if (field.field_type != void) {
                    try st.serializeField(field.name, @field(value, field.name));
                }
            }
            return try st.end();
        }
    };
};

fn Return(comptime Serializer: type) type {
    getty.concepts.@"getty.Serializer"(Serializer);

    return Serializer.Error!Serializer.Ok;
}
