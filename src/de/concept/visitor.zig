const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.Visitor";

pub fn @"getty.de.Visitor"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            concepts.err(concept, "missing `context` field");
        }

        if (!@hasDecl(T, "Value")) {
            concepts.err(concept, "missing `Value` declaration");
        }

        inline for (.{
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
