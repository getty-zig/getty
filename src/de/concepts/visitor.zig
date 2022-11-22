const std = @import("std");

const concept = "getty.de.Visitor";

/// Compile-time type restraint for `getty.de.Visitor`.
pub fn @"getty.de.Visitor"(
    /// A type that implements `getty.de.Visitor`.
    comptime T: type,
) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` field", .{concept}));
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
            "visitUnion",
            "visitVoid",
        }) |decl| {
            if (!@hasDecl(T, decl)) {
                @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `{s}` declaration", .{ concept, decl }));
            }
        }
    }
}
