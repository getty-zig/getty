//! Compile-time type restraint for implementations of getty.ser.Map.

const std = @import("std");

const concept = "getty.ser.Map";

pub fn @"getty.ser.Map"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` field", .{concept}));
        }

        inline for (.{ "Ok", "Error" }) |decl| {
            if (!@hasDecl(T, decl)) {
                @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `{s}` declaration", .{ concept, decl }));
            }
        }

        inline for (.{ "serializeKey", "serializeValue", "end" }) |func| {
            if (!std.meta.trait.hasFunctions(T, .{func})) {
                @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `{s}` function", .{ concept, func }));
            }
        }
    }
}
