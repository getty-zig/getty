const std = @import("std");

const concept = "getty.Serializer";

/// Specifies that a type is a `getty.Serializer` interface type.
pub fn @"getty.Serializer"(
    /// A type to check.
    comptime T: type,
) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` field", .{concept}));
        }

        inline for (.{
            "Ok",
            "Error",
            "st",
            "user_st",
            "serializer_st",
            "serializeBool",
            "serializeEnum",
            "serializeFloat",
            "serializeInt",
            "serializeMap",
            "serializeNull",
            "serializeSeq",
            "serializeSome",
            "serializeString",
            "serializeStruct",
            "serializeVoid",
        }) |decl| {
            if (!@hasDecl(T, decl)) {
                @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `{s}` declaration", .{decl}));
            }
        }
    }
}
