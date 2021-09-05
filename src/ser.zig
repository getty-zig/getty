const std = @import("std");

pub const ser = struct {
    pub usingnamespace @import("ser/interface.zig");
    pub usingnamespace @import("ser/impl.zig");
};

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
        var visitor = ser.ArrayListVisitor{};
        return try serializeWith(serializer, visitor.visitor(), value);
    } else if (comptime match("std.hash_map.HashMap", @typeName(T))) {
        var visitor = ser.StringHashMapVisitor{};
        return try serializeWith(serializer, visitor.visitor(), value);
    }

    var visitor = switch (@typeInfo(T)) {
        .Array => ser.SeqVisitor{},
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
                false => ser.SeqVisitor{},
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

    return try serializeWith(serializer, visitor.visitor(), value);
}

fn match(comptime expected: []const u8, comptime actual: []const u8) bool {
    if (actual.len >= expected.len and std.mem.eql(u8, actual[0..expected.len], expected)) {
        return true;
    }

    return false;
}
