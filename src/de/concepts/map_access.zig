const std = @import("std");

const concept = "getty.de.MapAccess";

pub fn @"getty.de.MapAccess"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` field", .{concept}));
        }

        if (!@hasDecl(T, "Error")) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `Error` declaration", .{concept}));
        }

        inline for (.{
            "nextKeySeed",
            "nextValueSeed",
            "nextKey",
            "nextValue",
        }) |func| {
            if (!std.meta.trait.hasFunctions(T, .{func})) {
                @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `{s}` function", .{ concept, func }));
            }
        }
    }
}
