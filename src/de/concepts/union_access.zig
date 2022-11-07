//! Compile-time type restraint for implementations of getty.de.UnionAccess.

const std = @import("std");

const concept = "getty.de.UnionAccess";

pub fn @"getty.de.UnionAccess"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` field", .{concept}));
        }

        if (!@hasDecl(T, "Error")) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `Error` declaration", .{concept}));
        }

        if (!std.meta.trait.hasFn("variantSeed")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `variantSeed` function", .{concept}));
        }
    }
}
