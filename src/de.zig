pub const interface = struct {
    pub usingnamespace @import("de/interface.zig");
};

pub const impl = struct {
    pub usingnamespace @import("de/impl.zig");
};

pub fn deserialize(comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
    switch (@typeInfo(T)) {
        .Bool => {
            var visitor = impl.BoolVisitor{};
            return try deserializer.deserializeBool(visitor.visitor());
        },
        .Float, .ComptimeFloat => {
            var visitor = impl.FloatVisitor(T){};
            return try deserializer.deserializeFloat(visitor.visitor());
        },
        .Int, .ComptimeInt => {
            var visitor = impl.IntVisitor(T){};
            return try deserializer.deserializeInt(visitor.visitor());
        },
        .Optional => {
            var visitor = impl.OptionalVisitor(T){};
            return try deserializer.deserializeOptional(visitor.visitor());
        },
        .Void => {
            var visitor = impl.VoidVisitor{};
            return try deserializer.deserializeVoid(visitor.visitor());
        },
        else => unreachable,
    }
}
