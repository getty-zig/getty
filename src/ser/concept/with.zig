const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.ser.sbt";

pub fn @"getty.ser.sbt"(comptime sbt: anytype) void {
    comptime concepts.Concept(concept, "")(.{
        check(sbt),
    });
}

fn check(comptime sbt: anytype) bool {
    const T = if (@TypeOf(sbt) == type) sbt else @TypeOf(sbt);
    const info = @typeInfo(T);

    if (info != .Struct) {
        return false;
    }

    if (info.Struct.is_tuple) {
        inline for (std.meta.fields(T)) |field| {
            if (!is_sb(@field(sbt, field.name))) {
                return false;
            }
        }
    } else if (!is_sb(T)) {
        return false;
    }

    return true;
}

fn is_sb(comptime T: type) bool {
    const info = @typeInfo(T);

    return info == .Struct and
        !info.Struct.is_tuple and
        info.Struct.fields.len == 0 and
        concepts.traits.hasFunctions(T, .{ "is", "serialize" });
}
