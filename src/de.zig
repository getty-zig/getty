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
const ArrayListVisitor = @import("de/impl/visitor/array_list.zig").Visitor;
const BoolVisitor = @import("de/impl/visitor/bool.zig");
const EnumVisitor = @import("de/impl/visitor/enum.zig").Visitor;
const FloatVisitor = @import("de/impl/visitor/float.zig").Visitor;
const IntVisitor = @import("de/impl/visitor/int.zig").Visitor;
const OptionalVisitor = @import("de/impl/visitor/optional.zig").Visitor;
const PointerVisitor = @import("de/impl/visitor/pointer.zig").Visitor;
const SliceVisitor = @import("de/impl/visitor/slice.zig").Visitor;
const StructVisitor = @import("de/impl/visitor/struct.zig").Visitor;
const VoidVisitor = @import("de/impl/visitor/void.zig");

const BoolDe = @import("de/impl/de/bool.zig").De;
const EnumDe = @import("de/impl/de/enum.zig").De;
const FloatDe = @import("de/impl/de/float.zig").De;
const IntDe = @import("de/impl/de/int.zig").De;
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
        pub usingnamespace @import("de/impl/seed/default.zig");
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
            else => @compileError("pointer type is not supported"),
        },
        .Struct => |info| blk: {
            if (comptime match("std.array_list.ArrayList", @typeName(T))) {
                break :blk ArrayListVisitor(T){ .allocator = allocator.? };
            } else switch (info.is_tuple) {
                true => @compileError("tuple serialization is not supported"),
                false => break :blk StructVisitor(T){ .allocator = allocator },
            }
        },
        .Void => VoidVisitor{},
        else => unreachable,
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
        .Pointer => |info| switch (info.size) {
            .One => return try _deserialize(allocator, std.meta.Child(T), deserializer, visitor),
            .Slice => switch (comptime std.meta.trait.isZigString(T)) {
                true => StringDe(Visitor){ .visitor = visitor },
                false => SequenceDe(Visitor){ .visitor = visitor },
            },
            else => @compileError("pointer type is not supported"),
        },
        .Struct => |info| blk: {
            if (comptime match("std.array_list.ArrayList", @typeName(T))) {
                break :blk SequenceDe(Visitor){ .visitor = visitor };
            } else switch (info.is_tuple) {
                false => break :blk StructDe(Visitor){ .visitor = visitor },
                true => @compileError("tuple deserialization is not supported"),
            }
        },
        .Void => VoidDe(Visitor){ .visitor = visitor },
        else => unreachable,
    };

    return try deserializeWith(allocator, Visitor.Value, deserializer, d.de());
}

fn match(comptime expected: []const u8, comptime actual: []const u8) bool {
    if (actual.len >= expected.len and std.mem.eql(u8, actual[0..expected.len], expected)) {
        return true;
    }

    return false;
}
