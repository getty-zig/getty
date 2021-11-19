const std = @import("std");

pub fn @"getty.Ser"(comptime T: type) void {
    const err = "expected `getty.Ser` interface value, found `" ++ @typeName(T) ++ "`";

    comptime {
        // Invariants
        if (!std.meta.trait.isContainer(T)) {
            @compileError(err);
        }

        // Constraints
        const has_name = std.mem.startsWith(u8, @typeName(T), "getty.Ser");
        const has_field = std.meta.trait.hasField("context")(T);
        const has_func = std.meta.trait.hasFn("serialize")(T);

        if (!(has_name and has_field and has_func)) {
            @compileError(err);
        }
    }
}
