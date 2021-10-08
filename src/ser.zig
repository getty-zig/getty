//! Serialization framework.
//!
//! The serialization process consists of 2 stages:
//!
//!     1. Conversion of Zig data into Getty's data model.
//!     2. Conversion from Getty's data model into a data format.
//!
//! The conversion into Getty's data model is performed by a serialize, while
//! the conversion into data formats is performed by a serializer.
//!
//! Visually, serialization looks like this:
//!
//!                  Zig data
//!
//!                     ↓
//!
//!                 Serialize
//!
//!                     ↓
//!
//!              Getty Data Model
//!
//!                     ↓
//!
//!                 Serializer
//!
//!                     ↓
//!
//!                Data Format
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
//! both considered to be the same type: struct. Therefore, if a serializer
//! supports struct (as defined by Getty) serialization, then by definition it
//! supports serialization for `struct { x: i32 }` values, `struct { y: bool }`
//! values, and values of any other struct type (assuming the type is composed
//! of data types supported by Getty).
//!
//! For more granular serialization, type information may still be used.  For
//! example, a serializer could support serialization of only `u32` and `u64`
//! values instead of all integers by simply inspecting the `bits` fields in
//! the integer's type information.
//!
//! # Serializes
//!
//! A serialize defines how to convert Zig data types into Getty's data model.
//! For example, the `BoolSer` defined by Getty converts `bool` values into the
//! Boolean type, which is one of the types defined in Getty's data model.
//!
//! If the behavior of the default serializes provided by Getty aren't suitable
//! for your use-case, then you may define and use your own custom
//! serialization logic by creating a serialize yourself.
//!
//! # Serializers
//!
//! Serializers define how to convert from Getty's data model into an output
//! data format. For example, a JSON serializer would specify that Getty
//! strings should be serialized as `"STRING"`.

const std = @import("std");

const ArrayListSer = @import("ser/impl/ser/array_list.zig");
const BoolSer = @import("ser/impl/ser/bool.zig");
const ErrorSer = @import("ser/impl/ser/error.zig");
const EnumSer = @import("ser/impl/ser/enum.zig");
const FloatSer = @import("ser/impl/ser/float.zig");
const IntSer = @import("ser/impl/ser/int.zig");
const OptionalSer = @import("ser/impl/ser/optional.zig");
const PointerSer = @import("ser/impl/ser/pointer.zig");
const NullSer = @import("ser/impl/ser/null.zig");
const SequenceSer = @import("ser/impl/ser/sequence.zig");
const StringSer = @import("ser/impl/ser/string.zig");
const HashMapSer = @import("ser/impl/ser/hash_map.zig");
const StructSer = @import("ser/impl/ser/struct.zig");
const TupleSer = @import("ser/impl/ser/tuple.zig");
const UnionSer = @import("ser/impl/ser/union.zig");
const VectorSer = @import("ser/impl/ser/vector.zig");
const VoidSer = @import("ser/impl/ser/void.zig");

/// Serializer interface
pub usingnamespace @import("ser/interface/serializer.zig");

/// Serialization interface
pub usingnamespace @import("ser/interface/ser.zig");

pub const ser = struct {
    /// Generic error set for `getty.Ser` implementations.
    pub const Error = error{
        Unsupported,
    };

    /// Compound type serialization interfaces
    pub usingnamespace @import("ser/interface/serialize/map.zig");
    pub usingnamespace @import("ser/interface/serialize/sequence.zig");
    pub usingnamespace @import("ser/interface/serialize/struct.zig");
    pub usingnamespace @import("ser/interface/serialize/tuple.zig");
};

/// Serializes a value using a provided serializer and serialize.
///
/// `serializeWith` allows for data types that aren't supported by Getty to be
/// serialized. Additionally, the function enables the use of custom
/// serialization logic for data types that are supported.
pub fn serializeWith(value: anytype, serializer: anytype, s: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try s.serialize(value, serializer);
}

/// Serializes a value using a provided serializer and a default serialize.
///
/// Serializes are only provided for data types supported by Getty, plus a
/// few commonly used but unsupported types such as `std.ArrayList` and
/// `std.AutoHashMap`. For custom serialization or serialization of data types
/// not supported Getty, see `getty.serializeWith`.
pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    if (comptime match("std.array_list.ArrayList", @typeName(T))) {
        var s = ArrayListSer{};
        return try serializeWith(value, serializer, s.ser());
    } else if (comptime match("std.hash_map.HashMap", @typeName(T))) {
        var s = HashMapSer{};
        return try serializeWith(value, serializer, s.ser());
    }

    var s = switch (@typeInfo(T)) {
        .Array => SequenceSer{},
        .Bool => BoolSer{},
        .Enum, .EnumLiteral => EnumSer{},
        .ErrorSet => ErrorSer{},
        .Float, .ComptimeFloat => FloatSer{},
        .Int, .ComptimeInt => IntSer{},
        .Null => NullSer{},
        .Optional => OptionalSer{},
        .Pointer => |info| switch (info.size) {
            .One => PointerSer{},
            .Slice => switch (comptime std.meta.trait.isZigString(T)) {
                true => StringSer{},
                false => SequenceSer{},
            },
            else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
        },
        .Struct => |info| switch (info.is_tuple) {
            true => TupleSer{},
            false => StructSer{},
        },
        .Union => UnionSer{},
        .Vector => VectorSer{},
        .Void => VoidSer{},
        else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
    };

    return try serializeWith(value, serializer, s.ser());
}

fn match(comptime expected: []const u8, comptime actual: []const u8) bool {
    if (actual.len >= expected.len and std.mem.eql(u8, actual[0..expected.len], expected)) {
        return true;
    }

    return false;
}
