const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.Serializer";
const decls = .{ "Ok", "Error" };
const funcs = .{
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
};

pub fn @"getty.Serializer"(comptime T: type) void {
    comptime {
        // Invariants
        concepts.container(T);

        // Constraints
        const has_name = std.mem.startsWith(u8, @typeName(T), concept);
        const has_field = concepts.traits.hasField(T, "context");
        const has_decls = for (decls) |d| {
            if (!concepts.traits.hasDecl(T, d)) return false;
        } else true;
        const has_funcs = for (funcs) |f| {
            if (!concepts.traits.hasFunction(T, f)) return false;
        } else true;

        if (!(has_name and has_field and has_decls and has_funcs)) {
            concepts.fail(concept, "");
        }
    }
}
