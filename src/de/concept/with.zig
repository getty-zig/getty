const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.de.with";

pub fn @"getty.de.with"(comptime with: anytype) void {
    comptime concepts.Concept(concept, "")(.{
        check(with),
    });
}

fn check(comptime with: anytype) bool {
    const T = if (@TypeOf(with) == type) with else @TypeOf(with);
    const info = @typeInfo(T);

    if (info != .Struct) {
        return false;
    }

    if (info.Struct.is_tuple) {
        inline for (std.meta.fields(T)) |field| {
            if (!is_with_block(@field(with, field.name))) {
                return false;
            }
        }
    } else if (!is_with_block(T)) {
        return false;
    }

    return true;
}

fn is_with_block(comptime T: type) bool {
    const info = @typeInfo(T);

    return info == .Struct and
        !info.Struct.is_tuple and
        info.Struct.fields.len == 0 and
        concepts.traits.hasFunctions(T, .{ "is", "visitor", "deserialize" });
}
