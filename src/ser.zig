const std = @import("std");

const meta = std.meta;

// Interfaces
pub const Serializer = @import("ser/interfaces/serializer.zig").Serializer;
pub const Visitor = @import("ser/interfaces/visitor.zig").Visitor;

pub const Map = @import("ser/interfaces/serialize/map.zig").Serialize;
pub const Sequence = @import("ser/interfaces/serialize/sequence.zig").Serialize;
pub const Structure = @import("ser/interfaces/serialize/structure.zig").Serialize;
pub const Tuple = Sequence;

// Implementations
pub const ArrayListVisitor = @import("ser/impls/visitors/array_list.zig");
pub const BoolVisitor = @import("ser/impls/visitors/bool.zig");
pub const ErrorVisitor = @import("ser/impls/visitors/error.zig");
pub const EnumVisitor = @import("ser/impls/visitors/enum.zig");
pub const FloatVisitor = @import("ser/impls/visitors/float.zig");
pub const IntVisitor = @import("ser/impls/visitors/int.zig");
pub const OptionalVisitor = @import("ser/impls/visitors/optional.zig");
pub const PointerVisitor = @import("ser/impls/visitors/pointer.zig");
pub const NullVisitor = @import("ser/impls/visitors/null.zig");
pub const SequenceVisitor = @import("ser/impls/visitors/sequence.zig");
pub const StringVisitor = @import("ser/impls/visitors/string.zig");
pub const StringHashMapVisitor = @import("ser/impls/visitors/string_hash_map.zig");
pub const StructVisitor = @import("ser/impls/visitors/struct.zig");
pub const TupleVisitor = @import("ser/impls/visitors/tuple.zig");
pub const UnionVisitor = @import("ser/impls/visitors/union.zig");
pub const VectorVisitor = @import("ser/impls/visitors/vector.zig");
pub const VoidVisitor = @import("ser/impls/visitors/void.zig");

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
