const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.Ser";

pub fn @"getty.Ser"(comptime T: type) void {
    comptime concepts.Concept(concept, "")(.{
        is_namespace(T),
        has_blocks(T),
    });
}

fn is_namespace(comptime T: type) bool {
    const info = @typeInfo(T);

    return info == .Struct and info.Struct.fields.len == 0;
}

fn has_blocks(comptime T: type) bool {
    comptime std.debug.assert(is_namespace(T));

    for (@typeInfo(T).Struct.decls) |d| {
        if (!is_block(@field(T, d.name))) {
            return false;
        }
    }

    return true;
}

fn is_block(comptime T: type) bool {
    const F = @TypeOf(struct {
        fn f(_: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            undefined;
        }
    }.f);

    return is_namespace(T) and
        concepts.traits.hasFunctions(T, .{ "is", "serialize" }) and
        T.is == fn (comptime T: type) bool and
        T.serialize == F;
}
