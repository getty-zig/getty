const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.Deserializer";

pub fn @"getty.Deserializer"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        inline for (.{
            "Error",
            "dt",
            "deserializeBool",
            "deserializeEnum",
            "deserializeFloat",
            "deserializeInt",
            "deserializeMap",
            "deserializeOptional",
            "deserializeSeq",
            "deserializeString",
            "deserializeStruct",
            "deserializeVoid",
        }) |decl| {
            if (!@hasDecl(T, decl)) {
                concepts.err(concept, "missing `" ++ decl ++ "` declaration");
            }
        }
    }
}
