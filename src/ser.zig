//! Serialization framework
//!
//! This module converts Zig data types into Getty's data model. Conversions
//! are done by a serializer and defined by a visitor.
//!
//! Interfaces:
//!
//!   * `Serializer`: A data format that can serialize any data type supported by Getty.
//!   * `Visitor`: A specification of the serialization process.
//!
//!   * `MapSerialize`: A specification of the serialization process for a map.
//!   * `SequenceSerialize`: A specification of the serialization process for a sequence.
//!   * `StructSerialize`: A specification of the serialization process for a struct.
//!   * `TupleSerialize`: A specification of the serialization process for a tuple.

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
