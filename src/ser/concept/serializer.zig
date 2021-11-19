const std = @import("std");

pub fn @"getty.Serializer"(comptime T: type) void {
    const err = "expected `getty.Serializer` interface value, found `" ++ @typeName(T) ++ "`";

    comptime {
        // Invariants
        if (!std.meta.trait.isContainer(T)) {
            @compileError(err);
        }

        // Constraints
        const has_name = std.mem.startsWith(u8, @typeName(T), "getty.Serializer");
        const has_field = std.meta.trait.hasField("context")(T);
        const has_decls = std.meta.trait.hasDecls(T, .{ "Ok", "Error" });
        const has_funcs = std.meta.trait.hasFunctions(T, .{
            "serializeBool",
            "serializeEnum",
            "serializeFloat",
            "serializeInt",
            "serializeMap",
            "serializeNull",
            "serializeSequence",
            "serializeSome",
            "serializeString",
            "serializeStruct",
            "serializeTuple",
            "serializeVoid",
        });

        if (!(has_name and has_field and has_decls and has_funcs)) {
            @compileError(err);
        }
    }
}
