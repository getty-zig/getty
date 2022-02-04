const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.ser.with";

pub fn @"getty.ser.with"(comptime T: type) void {
    comptime concepts.Concept(concept, "")(.{
        check(T),
    });
}

fn check(comptime T: type) bool {
    switch (@typeInfo(T)) {
        .Struct => |info| {
            if (!info.is_tuple) {
                return false;
            }

            inline for (std.meta.declarations(T)) |decl| {
                if (!is_with_block(@TypeOf(@field(T, decl.name)))) {
                    return false;
                }
            }

            return true;
        },
        .Optional => |info| {
            if (std.meta.trait.isTuple(info.child)) {
                return check(info.child);
            }

            return false;
        },
        else => return T == @Type(.Null),
    }
}

fn is_with_block(comptime T: type) bool {
    const info = @typeInfo(T);

    return info == .Struct and
        info.Struct.fields.len == 0 and
        concepts.traits.hasFunctions(T, .{ "is", "serialize" });
}
