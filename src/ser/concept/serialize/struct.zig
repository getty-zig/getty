const std = @import("std");

pub fn @"getty.ser.StructSerialize"(comptime T: type) void {
    const err = "expected `getty.ser.StructSerialize` interface value, found `" ++ @typeName(T) ++ "`";

    comptime {
        // Invariants
        if (!std.meta.trait.isContainer(T)) {
            @compileError(err);
        }

        // Constraints
        const has_name = std.mem.startsWith(u8, @typeName(T), "getty.ser.StructSerialize");
        const has_field = std.meta.trait.hasField("context")(T);
        const has_decls = std.meta.trait.hasDecls(T, .{ "Ok", "Error" });
        const has_funcs = std.meta.trait.hasFunctions(T, .{
            "serializeField",
            "end",
        });

        if (!(has_name and has_field and has_decls and has_funcs)) {
            @compileError(err);
        }
    }
}
