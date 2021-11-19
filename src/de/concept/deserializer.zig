const std = @import("std");

pub fn @"getty.Deserializer"(comptime T: type) void {
    const err = "expected `getty.Deserializer` interface value, found `" ++ @typeName(T) ++ "`";

    comptime {
        // Invariants
        if (!std.meta.trait.isContainer(T)) {
            @compileError(err);
        }

        // Constraints
        const has_name = std.mem.startsWith(u8, @typeName(T), "getty.Deserializer");
        const has_field = std.meta.trait.hasField("context")(T);
        const has_decl = @hasDecl(T, "Error");
        const has_funcs = std.meta.trait.hasFunctions(T, .{
            "deserializeBool",
            "deserializeEnum",
            "deserializeFloat",
            "deserializeInt",
            "deserializeMap",
            "deserializeOptional",
            "deserializeSequence",
            "deserializeString",
            "deserializeStruct",
            "deserializeVoid",
        });

        if (!(has_name and has_field and has_decl and has_funcs)) {
            @compileError(err);
        }
    }
}
