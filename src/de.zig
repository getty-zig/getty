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
            var v = de.ArrayVisitor(T){};
            const visitor = v.visitor(allocator);
            return try deserializer.deserializeSequence(allocator, visitor);
        },
        .Bool => {
            var v = de.BoolVisitor{};
            const visitor = v.visitor(allocator);
            return try deserializer.deserializeBool(visitor);
        },
        .Enum => {
            var v = de.EnumVisitor(T){};
            const visitor = v.visitor(allocator);
            return try deserializer.deserializeEnum(visitor);
        },
        .Float, .ComptimeFloat => {
            var v = de.FloatVisitor(T){};
            const visitor = v.visitor(allocator);
            return try deserializer.deserializeFloat(visitor);
        },
        .Int, .ComptimeInt => {
            var v = de.IntVisitor(T){};
            const visitor = v.visitor(allocator);
            return try deserializer.deserializeInt(visitor);
        },
        .Optional => {
            var v = de.OptionalVisitor(T){};
            const visitor = v.visitor(allocator);
            return try deserializer.deserializeOptional(allocator, visitor);
        },
        .Pointer => |info| switch (info.size) {
            .Slice => {
                var v = de.SliceVisitor(T){};
                const visitor = v.visitor(allocator);
                return try deserializer.deserializeSlice(allocator.?, visitor);
            },
            else => unreachable,
        },
        .Struct => |info| switch (info.is_tuple) {
            true => @compileError("tuple deserialization is not supported"),
            false => {
                var v = de.StructVisitor(T){};
                const visitor = v.visitor(allocator);
                return try deserializer.deserializeStruct(allocator, visitor);
            },
        },
        .Void => {
            var v = de.VoidVisitor{};
            const visitor = v.visitor(allocator);
            return try deserializer.deserializeVoid(visitor);
        },
        else => unreachable,
    }
}
