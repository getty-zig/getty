//! Compile-time type restraint for implementations of getty.de.VariantAccess.

const std = @import("std");

const concept = "getty.de.VariantAccess";

pub fn @"getty.de.VariantAccess"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` field", .{concept}));
        }

        if (!@hasDecl(T, "Error")) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `Error` declaration", .{concept}));
        }

        if (!std.meta.trait.hasFn("payloadSeed")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `payloadSeed` function", .{concept}));
        }
    }
}
