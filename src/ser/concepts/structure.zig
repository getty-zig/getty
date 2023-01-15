const std = @import("std");

const concept = "getty.ser.Structure";

/// Specifies that a type is a `getty.ser.Structure` interface type.
pub fn @"getty.ser.Structure"(
    /// A type to check.
    comptime T: type,
) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` field", .{concept}));
        }

        inline for (.{ "Ok", "Error" }) |decl| {
            if (!@hasDecl(T, decl)) {
                @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `{s}` declaration", .{decl}));
            }
        }

        inline for (.{ "serializeField", "end" }) |func| {
            if (!std.meta.trait.hasFunctions(T, .{func})) {
                @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `{s}` function", .{func}));
            }
        }
    }
}
