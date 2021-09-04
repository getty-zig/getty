// Interfaces
pub usingnamespace @import("de/interface/interface.zig");

// Implementations
pub const Seed = @import("de/impls/seed.zig").Seed;

pub const BoolVisitor = @import("de/impls/visitors/bool.zig");
pub const FloatVisitor = @import("de/impls/visitors/float.zig").Visitor;
pub const IntVisitor = @import("de/impls/visitors/int.zig").Visitor;
pub const OptionalVisitor = @import("de/impls/visitors/optional.zig").Visitor;
pub const VoidVisitor = @import("de/impls/visitors/void.zig");

pub fn deserialize(comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
    switch (@typeInfo(T)) {
        .Bool => {
            var visitor = BoolVisitor{};
            return try deserializer.deserializeBool(visitor.visitor());
        },
        .Float, .ComptimeFloat => {
            var visitor = FloatVisitor(T){};
            return try deserializer.deserializeFloat(visitor.visitor());
        },
        .Int, .ComptimeInt => {
            var visitor = IntVisitor(T){};
            return try deserializer.deserializeInt(visitor.visitor());
        },
        .Optional => {
            var visitor = OptionalVisitor(T){};
            return try deserializer.deserializeOptional(visitor.visitor());
        },
        .Void => {
            var visitor = VoidVisitor{};
            return try deserializer.deserializeVoid(visitor.visitor());
        },
        else => unreachable,
    }
}
