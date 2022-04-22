const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.Visitor";

pub fn @"getty.de.Visitor"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        inline for (.{
            "Value",
            "visitBool",
            "visitEnum",
            "visitFloat",
            "visitInt",
            "visitMap",
            "visitNull",
            "visitSeq",
            "visitSome",
            "visitString",
            "visitVoid",
        }) |decl| {
            if (!@hasDecl(T, decl)) {
                concepts.err(concept, "missing `" ++ decl ++ "` declaration");
            }
        }
    }
}
