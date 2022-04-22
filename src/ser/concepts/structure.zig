const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.ser.Structure";

pub fn @"getty.ser.Structure"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        inline for (.{ "Ok", "Error" }) |decl| {
            if (!@hasDecl(T, decl)) {
                concepts.err(concept, "missing `" ++ decl ++ "` declaration");
            }
        }

        inline for (.{ "serializeField", "end" }) |func| {
            if (!std.meta.trait.hasFunctions(T, .{func})) {
                concepts.err(concept, "missing `" ++ func ++ "` function");
            }
        }
    }
}
