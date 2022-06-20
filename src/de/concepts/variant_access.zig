const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.VariantAccess";

pub fn @"getty.de.VariantAccess"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        if (!@hasDecl(T, "Error")) {
            concepts.err(concept, "missing `Error` declaration");
        }

        if (!std.meta.trait.hasFn("payloadSeed")(T)) {
            concepts.err(concept, "missing `payloadSeed` function");
        }
    }
}
