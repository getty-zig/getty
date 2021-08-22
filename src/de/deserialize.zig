const de = @import("../lib.zig").de;

pub fn deserialize(comptime T: type, deserializer: anytype) @TypeOf(deserializer).Error!T {
    var visitor = switch (@typeInfo(T)) {
        .Bool => de.BoolVisitor{},
        .Float, .ComptimeFloat => de.FloatVisitor(T){},
        .Int, .ComptimeInt => de.IntVisitor(T){},
        .Void => de.VoidVisitor{},
        else => unreachable,
    };

    return try deserializer.deserializeAny(visitor.visitor());
}
