const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.de.with";

pub fn @"getty.de.with"(comptime T: type) void {
    comptime concepts.Concept(concept, "")(.{
        check(T),
    });
}

fn check(comptime T: type) bool {
    if (!is_namespace(T)) {
        return false;
    }

    inline for (@typeInfo(T).Struct.decls) |d| {
        if (!is_block(@field(T, d.name))) {
            return false;
        }
    }

    return true;
}

fn is_namespace(comptime T: type) bool {
    const info = @typeInfo(T);

    return info == .Struct and info.Struct.fields.len == 0;
}

fn is_block(comptime T: type) bool {
    // This is the best we can do without relaxed generic type erasure.
    return is_namespace(T) and concepts.traits.hasFunctions(T, .{
        "is",
        "visitor",
        "deserialize",
    });
}
