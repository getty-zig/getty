const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.Seed";

pub fn @"getty.de.Seed"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        if (!std.meta.trait.hasFunctions(T, .{"deserialize"})) {
            concepts.err(concept, "missing `deserialize` function");
        }
    }
}
