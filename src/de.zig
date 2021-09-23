const Allocator = @import("std").mem.Allocator;

pub const de = struct {
    pub usingnamespace @import("de/interface.zig");
    usingnamespace @import("de/impl.zig");
};

pub fn deserialize(
    allocator: ?*Allocator,
    comptime T: type,
    deserializer: anytype,
) @TypeOf(deserializer).Error!T {
    _ = allocator;

    switch (@typeInfo(T)) {
        .Array => {
            var visitor = de.ArrayVisitor(T){};
            return try deserializer.deserializeSequence(allocator, visitor.visitor());
        },
        .Bool => {
            var visitor = de.BoolVisitor{};
            return try deserializer.deserializeBool(visitor.visitor());
        },
        .Enum => {
            var visitor = de.EnumVisitor(T){};
            return try deserializer.deserializeEnum(visitor.visitor());
        },
        .Float, .ComptimeFloat => {
            var visitor = de.FloatVisitor(T){};
            return try deserializer.deserializeFloat(visitor.visitor());
        },
        .Int, .ComptimeInt => {
            var visitor = de.IntVisitor(T){};
            return try deserializer.deserializeInt(visitor.visitor());
        },
        .Optional => {
            var visitor = de.OptionalVisitor(T){};
            return try deserializer.deserializeOptional(allocator, visitor.visitor());
        },
        .Pointer => |info| switch (info.size) {
            .Slice => {
                var visitor = de.SliceVisitor(T){};
                return try deserializer.deserializeSlice(allocator.?, visitor.visitor());
            },
            else => unreachable,
        },
        .Struct => |info| switch (info.is_tuple) {
            true => @compileError("tuple deserialization is not supported"),
            false => {
                var visitor = de.StructVisitor(T){};
                return try deserializer.deserializeStruct(allocator, visitor.visitor());
            },
        },
        .Void => {
            var visitor = de.VoidVisitor{};
            return try deserializer.deserializeVoid(visitor.visitor());
        },
        else => unreachable,
    }
}
