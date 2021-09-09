const Allocator = @import("std").mem.Allocator;

pub const de = struct {
    pub usingnamespace @import("de/interface.zig");
    pub usingnamespace @import("de/impl.zig");
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
        .Void => {
            var visitor = de.VoidVisitor{};
            return try deserializer.deserializeVoid(visitor.visitor());
        },
        else => unreachable,
    }
}
