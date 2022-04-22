const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.Map";

pub fn @"getty.de.Map"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        if (!@hasDecl(T, "Error")) {
            concepts.err(concept, "missing `Error` declaration");
        }

        inline for (.{
            "nextKeySeed",
            "nextValueSeed",
            "nextKey",
            "nextValue",
        }) |func| {
            if (!std.meta.trait.hasFunctions(T, .{func})) {
                concepts.err(concept, "missing `" ++ func ++ "` function");
            }
        }
    }
}
