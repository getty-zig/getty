const std = @import("std");
const meta = std.meta;

const ArrayListVisitor = @import("../lib.zig").ser.ArrayListVisitor;
const BoolVisitor = @import("../lib.zig").ser.BoolVisitor;
const EnumVisitor = @import("../lib.zig").ser.EnumVisitor;
const ErrorVisitor = @import("../lib.zig").ser.ErrorVisitor;
const FloatVisitor = @import("../lib.zig").ser.FloatVisitor;
const IntVisitor = @import("../lib.zig").ser.IntVisitor;
const NullVisitor = @import("../lib.zig").ser.NullVisitor;
const OptionalVisitor = @import("../lib.zig").ser.OptionalVisitor;
const PointerVisitor = @import("../lib.zig").ser.PointerVisitor;
const SequenceVisitor = @import("../lib.zig").ser.SequenceVisitor;
const StringVisitor = @import("../lib.zig").ser.StringVisitor;
const StringHashMapVisitor = @import("../lib.zig").ser.StringHashMapVisitor;
const StructVisitor = @import("../lib.zig").ser.StructVisitor;
const TupleVisitor = @import("../lib.zig").ser.TupleVisitor;
const UnionVisitor = @import("../lib.zig").ser.UnionVisitor;
const VectorVisitor = @import("../lib.zig").ser.VectorVisitor;
const VoidVisitor = @import("../lib.zig").ser.VoidVisitor;

/// Serialize values outside of Getty's data model.
///
/// This function enables custom serialization for data types within Getty's
/// data model and serialization for data types outside of Getty's data model.
pub fn serializeWith(serializer: anytype, value: anytype, visitor: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
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
        return try serializeWith(serializer, value, visitor.visitor());
    } else if (comptime match("std.hash_map.HashMap", @typeName(T))) {
        var visitor = StringHashMapVisitor{};
        return try serializeWith(serializer, value, visitor.visitor());
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

    return try serializeWith(serializer, value, visitor.visitor());
}

fn match(comptime expected: []const u8, comptime actual: []const u8) bool {
    if (actual.len >= expected.len and std.mem.eql(u8, actual[0..expected.len], expected)) {
        return true;
    }

    return false;
}
