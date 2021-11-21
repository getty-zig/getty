const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.Ser";

pub fn @"getty.Ser"(comptime T: type) void {
    comptime concepts.Concept(concept, "")(.{
        std.mem.eql(u8, @typeName(T), concept),
        concepts.traits.hasField(T, "context"),
        concepts.traits.hasFunction(T, "serialize"),
    });
}
