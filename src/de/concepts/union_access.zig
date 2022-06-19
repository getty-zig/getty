const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.UnionAccess";

pub fn @"getty.de.UnionAccess"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        inline for (.{ "Error", "Variant" }) |decl| {
            if (!@hasDecl(T, decl)) {
                concepts.err(concept, "missing `" ++ decl ++ "` declaration");
            }
        }

        if (!std.meta.trait.hasFn("variantSeed")(T)) {
            concepts.err(concept, "missing `variantSeed` function");
        }
    }
}
