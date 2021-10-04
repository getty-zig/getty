const std = @import("std");
const getty = @import("lib.zig");

pub const de = struct {
    pub const Error = std.mem.Allocator.Error || error{
        Unsupported,

        DuplicateField,
        InvalidLength,
        InvalidType,
        InvalidValue,
        MissingField,
        UnknownField,
        UnknownVariant,
    };

    pub const DefaultDeserialize = struct {
        pub usingnamespace getty.Deserialize(
            Self,
            _deserialize,
        );

        const Self = @This();

        fn _deserialize(
            self: Self,
            allocator: ?*std.mem.Allocator,
            comptime T: type,
            deserializer: anytype,
        ) @TypeOf(deserializer).Error!T {
            _ = self;

            var v = switch (@typeInfo(T)) {
                .Array => de.ArrayVisitor(T){},
                .Bool => de.BoolVisitor{},
                .Enum => de.EnumVisitor(T){},
                .Float, .ComptimeFloat => de.FloatVisitor(T){},
                .Int, .ComptimeInt => de.IntVisitor(T){},
                .Optional => de.OptionalVisitor(T){ .allocator = allocator },
                .Pointer => |info| switch (info.size) {
                    .One => de.PointerVisitor(T){ .allocator = allocator.? },
                    .Slice => de.SliceVisitor(T){ .allocator = allocator.? },
                    else => @compileError("pointer type is not supported"),
                },
                .Struct => |info| switch (info.is_tuple) {
                    true => @compileError("tuple deserialization is not supported"),
                    false => de.StructVisitor(T){ .allocator = allocator },
                },
                .Void => de.VoidVisitor{},
                else => unreachable,
            };
            const visitor = v.visitor();

            std.debug.assert(T == @TypeOf(visitor).Value);

            return try __deserialize(allocator, T, deserializer, visitor);
        }

        inline fn __deserialize(
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
                    .Slice => deserializer.deserializeSlice(visitor),
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

    pub usingnamespace @import("de/interface.zig");
    usingnamespace @import("de/impl.zig");
};

pub usingnamespace @import("de/interface/deserialize.zig");
pub usingnamespace @import("de/interface/deserializer.zig");

pub fn deserializeWith(
    allocator: ?*std.mem.Allocator,
    comptime T: type,
    deserializer: anytype,
    spec: anytype,
) @TypeOf(deserializer).Error!T {
    return try spec.deserialize(allocator, T, deserializer);
}

pub fn deserialize(
    allocator: ?*std.mem.Allocator,
    comptime T: type,
    deserializer: anytype,
) @TypeOf(deserializer).Error!T {
    const spec = de.DefaultDeserialize{};
    return try deserializeWith(allocator, T, deserializer, spec.deserialize());
}
