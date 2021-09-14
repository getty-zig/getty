//! A framework for serializing Zig data into a data format.
//!
//! The serialization process consists of 2 stages:
//!
//!     1. Conversion of Zig data into Getty's data model.
//!     2. Conversion from Getty's data model into a data format.
//!
//! The conversion into Getty's data model is performed by **visitors**, while
//! the conversion into data formats is performed by **serializers**.
//!
//! # Data Model
//!
//! The Getty data model is the set of types supported by Getty. The types
//! within this set are conceptual; they are not actual Zig types. For example,
//! there is no `i32` or `u64` in Getty's data model. Instead, they are both
//! considered to be the same type: integer.
//!
//! By maintaining a data model, Getty establishes a generic baseline from
//! which serializers can operate. This can often simplify the job of a
//! serializer significantly. For example, Zig considers `struct { x: i32 }`
//! and `struct { y: bool }` to be different types. However, in Getty they are
//! both considered to be the same type: struct. Therefore, if a serializer
//! supports struct (as defined by Getty) serialization, then by definition it
//! supports serialization for `struct { x: i32 }` values, `struct { y: bool }`
//! values, and values of any other struct type (assuming the type is composed
//! of data types supported by Getty).
//!
//! Additionally, because type information remains available to serializers,
//! more granular serialization can be implemented if desired. For instance, a
//! serializer could support serialization of only `u32` and `u64` values
//! instead of all integers by simply inspecting the integer's type
//! information.
//!
//! # Visitors
//!
//! Visitors define how to convert Zig data types into Getty's data model. For
//! example, the `BoolVisitor` defined by Getty converts `bool` values into the
//! Boolean type, which is a conceptual type defined within Getty's data model.
//!
//! If the conversions used by the visitors provided by Getty aren't enough or
//! aren't suitable for your use-case, then you may create your own visitor and
//! define your own custom serialization logic. For instance, your visitor
//! could serialize `bool` values as integers by calling a serializer's
//! `serializeInt` method and passing in a 1 if the value is `true` or 0 if the
//! value is `false`.
//!
//! # Serializers
//!
//! Serializers define how to convert from Getty's data model into an output
//! data format. For example, a JSON serializer would specify that Getty
//! sequences (e.g., arrays, slices, array lists, linked lists) should be
//! serialized as `[<element>, <element>, ...]`.
//!
//! Getty does not define any serializers. It simply helps users build one
//! themselves.

const std = @import("std");

pub const ser = struct {
    pub usingnamespace @import("ser/interface.zig");
    pub usingnamespace @import("ser/impl.zig");
};

/// Serializes a value using a provided serializer and visitor.
///
/// `serializeWith` allows for data types that aren't supported by Getty to be
/// serialized. Additionally, the function enables the use of custom
/// serialization logic for data types that are supported.
pub fn serializeWith(value: anytype, serializer: anytype, visitor: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try visitor.serialize(value, serializer);
}

/// Serializes a value using a provided serializer and a default visitor.
///
/// Visitors are only provided for data types supported by Getty, plus a few
/// commonly used but unsupported types such as `std.ArrayList` and
/// `std.StringHashMap`. For custom serialization or serialization of data
/// types not supported Getty, see `getty.serializeWith`.
pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    if (comptime match("std.array_list.ArrayList", @typeName(T))) {
        var visitor = ser.ArrayListVisitor{};
        return try serializeWith(value, serializer, visitor.visitor());
    } else if (comptime match("std.hash_map.HashMap", @typeName(T))) {
        var visitor = ser.StringHashMapVisitor{};
        return try serializeWith(value, serializer, visitor.visitor());
    }

    var visitor = switch (@typeInfo(T)) {
        .Array => ser.SequenceVisitor{},
        .Bool => ser.BoolVisitor{},
        .Enum, .EnumLiteral => ser.EnumVisitor{},
        .ErrorSet => ser.ErrorVisitor{},
        .Float, .ComptimeFloat => ser.FloatVisitor{},
        .Int, .ComptimeInt => ser.IntVisitor{},
        .Null => ser.NullVisitor{},
        .Optional => ser.OptionalVisitor{},
        .Pointer => |info| switch (info.size) {
            .One => ser.PointerVisitor{},
            .Slice => switch (comptime std.meta.trait.isZigString(T)) {
                true => ser.StringVisitor{},
                false => ser.SequenceVisitor{},
            },
            else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
        },
        .Struct => |info| switch (info.is_tuple) {
            true => ser.TupleVisitor{},
            false => ser.StructVisitor{},
        },
        .Union => ser.UnionVisitor{},
        .Vector => ser.VectorVisitor{},
        .Void => ser.VoidVisitor{},
        else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
    };

    return try serializeWith(value, serializer, visitor.visitor());
}

fn match(comptime expected: []const u8, comptime actual: []const u8) bool {
    if (actual.len >= expected.len and std.mem.eql(u8, actual[0..expected.len], expected)) {
        return true;
    }

    return false;
}
