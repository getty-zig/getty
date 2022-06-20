const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.UnionAccess";

pub fn @"getty.de.UnionAccess"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        if (!@hasDecl(T, "Error")) {
            concepts.err(concept, "missing `Error` declaration");
        }

        if (!std.meta.trait.hasFn("variantSeed")(T)) {
            concepts.err(concept, "missing `variantSeed` function");
        }
    }
}
