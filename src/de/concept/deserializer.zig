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
        const has_decls = std.meta.trait.hasDecls(T, .{
            "Error",
            "with",
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

        if (!(has_name and has_field and has_decls)) {
            @compileError(err);
        }
    }
}
