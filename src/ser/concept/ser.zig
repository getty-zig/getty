const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.Ser";

pub fn @"getty.Ser"(comptime T: type) void {
    comptime {
        // Invariants
        concepts.container(T);

        // Constraints
        const has_name = std.mem.startsWith(u8, @typeName(T), concept);
        const has_field = concepts.traits.hasField(T, "context");
        const has_func = concepts.traits.hasFunction(T, "serialize");

        if (!(has_name and has_field and has_func)) {
            concepts.fail(concept);
        }
    }
}
