const std = @import("std");

const concepts = @import("concepts");

pub fn SerializeConcept(comptime concept: []const u8, comptime funcs: [][]const u8) type {
    return @TypeOf(struct {
        fn f(comptime T: type) void {
            comptime {
                // Invariants
                concepts.container(T);

                // Constraints
                const has_name = std.mem.startsWith(u8, @typeName(T), concept);
                const has_field = std.meta.trait.hasField("context")(T);
                const has_decls = if (concepts.traits.hasDecl(T, "Ok") and concepts.traits.hasDecl(T, "Error")) true else false;
                const has_funcs = for (funcs) |func| {
                    if (!concepts.traits.hasFunction(T, func)) return false;
                } else true;

                if (!(has_name and has_field and has_decls and has_funcs)) {
                    concepts.fail(concept, "");
                }
            }
        }
    }.f);
}
