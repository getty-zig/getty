const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.de.dbt";

/// Type constraint for Deserialization Blocks/Tuples.
pub fn @"getty.de.dbt"(comptime dbt: anytype) void {
    comptime concepts.Concept(concept, "")(.{
        check(dbt),
    });
}

fn check(comptime dbt: anytype) bool {
    const T = if (@TypeOf(dbt) == type) dbt else @TypeOf(dbt);
    const info = @typeInfo(T);

    if (info != .Struct) {
        return false;
    }

    if (info.Struct.is_tuple) {
        inline for (std.meta.fields(T)) |field| {
            if (!is_db(@field(dbt, field.name))) {
                return false;
            }
        }
    } else if (!is_db(T)) {
        return false;
    }

    return true;
}

fn is_db(comptime T: type) bool {
    const info = @typeInfo(T);

    return info == .Struct and
        !info.Struct.is_tuple and
        info.Struct.fields.len == 0 and
        concepts.traits.hasFunctions(T, .{ "is", "visitor", "deserialize" });
}
