const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.ser.with";

pub fn @"getty.ser.with"(comptime T: type) void {
    comptime concepts.Concept(concept, "")(.{
        check(T),
    });
}

fn check(comptime T: type) bool {
    const info = @typeInfo(T);

    if (info != .Struct) {
        return false;
    }

    if (info.Struct.is_tuple) {
        inline for (std.meta.declarations(T)) |decl| {
            if (!is_with_block(@TypeOf(@field(T, decl.name)))) {
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
        info.Struct.fields.len == 0 and
        concepts.traits.hasFunctions(T, .{ "is", "serialize" });
}
