const std = @import("std");

pub fn @"getty.de.Visitor"(comptime T: type) void {
    const err = "expected `getty.de.Visitor` interface value, found `" ++ @typeName(T) ++ "`";

    comptime {
        // Invariants
        if (!std.meta.trait.isContainer(T)) {
            @compileError(err);
        }

        // Constraints
        const has_name = std.mem.startsWith(u8, @typeName(T), "getty.de.Visitor");
        const has_field = std.meta.trait.hasField("context")(T);
        const has_decls = std.meta.trait.hasDecls(T, .{
            "Value",
            "visitBool",
            "visitEnum",
            "visitFloat",
            "visitInt",
            "visitMap",
            "visitNull",
            "visitSeq",
            "visitSome",
            "visitString",
            "visitVoid",
        });

        if (!(has_name and has_field and has_decls)) {
            @compileError(err);
        }
    }
}
