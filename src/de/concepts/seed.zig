const std = @import("std");

const concept = "getty.de.Seed";

/// Compile-time type restraint for `getty.de.Seed`.
pub fn @"getty.de.Seed"(
    /// A type that implements `getty.de.Seed`.
    comptime T: type,
) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` field", .{concept}));
        }

        if (!std.meta.trait.hasFn("deserialize")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `deserialize` function", .{concept}));
        }
    }
}
