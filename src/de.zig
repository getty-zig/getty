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

const ArrayVisitor = @import("de/impl/visitor/array.zig").Visitor;
const BoolVisitor = @import("de/impl/visitor/bool.zig");
const EnumVisitor = @import("de/impl/visitor/enum.zig").Visitor;
const FloatVisitor = @import("de/impl/visitor/float.zig").Visitor;
const IntVisitor = @import("de/impl/visitor/int.zig").Visitor;
const OptionalVisitor = @import("de/impl/visitor/optional.zig").Visitor;
const PointerVisitor = @import("de/impl/visitor/pointer.zig").Visitor;
const SliceVisitor = @import("de/impl/visitor/slice.zig").Visitor;
const StructVisitor = @import("de/impl/visitor/struct.zig").Visitor;
const VoidVisitor = @import("de/impl/visitor/void.zig");

const DefaultDeserialize = struct {
    const Self = @This();

    pub usingnamespace getty.De(
        Self,
        _deserialize,
    );

    fn _deserialize(
        _: Self,
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
                else => @compileError("pointer type is not supported"),
            },
            .Struct => |info| switch (info.is_tuple) {
                true => @compileError("tuple erialization is not supported"),
                false => StructVisitor(T){ .allocator = allocator },
            },
            .Void => VoidVisitor{},
            else => unreachable,
        };
        const visitor = v.visitor();

        std.debug.assert(T == @TypeOf(visitor).Value);

        return try __deserialize(allocator, T, deserializer, visitor);
    }

    fn __deserialize(
        allocator: ?*std.mem.Allocator,
        comptime T: type,
        deserializer: anytype,
        visitor: anytype,
    ) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
        return try switch (@typeInfo(T)) {
            .Array => deserializer.deserializeSequence(visitor),
            .Bool => deserializer.deserializeBool(visitor),
            .Enum => deserializer.deserializeEnum(visitor),
            .Float, .ComptimeFloat => deserializer.deserializeFloat(visitor),
            .Int, .ComptimeInt => deserializer.deserializeInt(visitor),
            .Optional => deserializer.deserializeOptional(visitor),
            .Pointer => |info| switch (info.size) {
                .One => __deserialize(allocator, std.meta.Child(T), deserializer, visitor),
                .Slice => blk: {
                    if (comptime std.meta.trait.isZigString(T)) {
                        break :blk deserializer.deserializeString(visitor);
                    } else {
                        break :blk deserializer.deserializeSequence(visitor);
                    }
                },
                else => @compileError("pointer type is not supported"),
            },
            .Struct => |info| switch (info.is_tuple) {
                true => @compileError("tuple deserialization is not supported"),
                false => deserializer.deserializeStruct(visitor),
            },
            .Void => deserializer.deserializeVoid(visitor),
            else => unreachable,
        };
    }
};

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

    /// Interfaces
    pub usingnamespace struct {
        /// Deserialization seed
        pub usingnamespace @import("de/interface/seed.zig");

        /// Visitor
        pub usingnamespace @import("de/interface/visitor.zig");

        /// Access for compound types
        pub usingnamespace @import("de/interface/access/map.zig");
        pub usingnamespace @import("de/interface/access/sequence.zig");
    };

    /// Implementations
    pub usingnamespace struct {
        // Default deserialization seed
        pub usingnamespace @import("de/impl/default_seed.zig");
    };
};

/// Performs deserialization using a provided serializer and `de`.
pub fn deserializeWith(allocator: ?*std.mem.Allocator, comptime T: type, deserializer: anytype, d: anytype) @TypeOf(deserializer).Error!T {
    return try d.deserialize(allocator, T, deserializer);
}

/// Performs deserialization using a provided serializer and a default `de`.
pub fn deserialize(allocator: ?*std.mem.Allocator, comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
    const d = DefaultDeserialize{};
    return try deserializeWith(allocator, T, deserializer, d.de());
}
