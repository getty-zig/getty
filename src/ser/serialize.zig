const ser = @import("../lib.zig").ser;
const std = @import("std");

const ArrayListVisitor = ser.ArrayListVisitor;
const BoolVisitor = ser.BoolVisitor;
const EnumVisitor = ser.EnumVisitor;
const ErrorVisitor = ser.ErrorVisitor;
const FloatVisitor = ser.FloatVisitor;
const IntVisitor = ser.IntVisitor;
const NullVisitor = ser.NullVisitor;
const OptionalVisitor = ser.OptionalVisitor;
const PointerVisitor = ser.PointerVisitor;
const SequenceVisitor = ser.SequenceVisitor;
const StringVisitor = ser.StringVisitor;
const StringHashMapVisitor = ser.StringHashMapVisitor;
const StructVisitor = ser.StructVisitor;
const TupleVisitor = ser.TupleVisitor;
const UnionVisitor = ser.UnionVisitor;
const VectorVisitor = ser.VectorVisitor;
const VoidVisitor = ser.VoidVisitor;

const meta = std.meta;

/// Serialize values outside of Getty's data model.
///
/// This function enables custom serialization for data types within Getty's
/// data model and serialization for data types outside of Getty's data model.
pub fn serializeWith(serializer: anytype, visitor: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try visitor.serialize(serializer, value);
}

/// Serialize values within Getty's data model.
///
/// Each value is serialized according to a visitor provided by Getty. The
/// visitor itself is specific to the type of the value being serialized, and
/// defines how the value is to be serialized (generally, in an expected
/// fashion).
///
/// Some commonly-used data types that fall outside of Getty's data model are
/// also supported, such as `std.ArrayList` and `std.StringHashMap`.
pub fn serialize(serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    if (comptime match("std.array_list.ArrayList", @typeName(T))) {
        var visitor = ArrayListVisitor{};
        return try serializeWith(serializer, visitor.visitor(), value);
    } else if (comptime match("std.hash_map.HashMap", @typeName(T))) {
        var visitor = StringHashMapVisitor{};
        return try serializeWith(serializer, visitor.visitor(), value);
    }

    var visitor = switch (@typeInfo(T)) {
        .Array => SequenceVisitor{},
        .Bool => BoolVisitor{},
        .Enum, .EnumLiteral => EnumVisitor{},
        .ErrorSet => ErrorVisitor{},
        .Float, .ComptimeFloat => FloatVisitor{},
        .Int, .ComptimeInt => IntVisitor{},
        .Null => NullVisitor{},
        .Optional => OptionalVisitor{},
        .Pointer => |info| switch (info.size) {
            .One => PointerVisitor{},
            .Slice => switch (comptime std.meta.trait.isZigString(T)) {
                true => StringVisitor{},
                false => SequenceVisitor{},
            },
            else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
        },
        .Struct => |info| switch (info.is_tuple) {
            true => TupleVisitor{},
            false => StructVisitor{},
        },
        .Union => UnionVisitor{},
        .Vector => VectorVisitor{},
        .Void => VoidVisitor{},
        else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
    };

    return try serializeWith(serializer, visitor.visitor(), value);
}

fn match(comptime expected: []const u8, comptime actual: []const u8) bool {
    if (actual.len >= expected.len and std.mem.eql(u8, actual[0..expected.len], expected)) {
        return true;
    }

    return false;
}
