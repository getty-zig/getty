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
        }) |decl| {
            if (!@hasDecl(T, decl)) {
                concepts.err(concept, "missing `" ++ decl ++ "` declaration");
            }
        }

        inline for (.{
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
        }) |func| {
            if (!std.meta.trait.hasFunctions(T, .{func})) {
                concepts.err(concept, "missing `" ++ func ++ "` function");
            }
        }

        if (!std.mem.eql(u8, @typeName(T), concept)) {
            concepts.err(concept, "mismatched types");
        }
    }
}
