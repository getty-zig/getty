const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.ser.Seq";

pub fn @"getty.ser.Seq"(comptime T: type) void {
    comptime concepts.Concept(concept, "")(.{
        std.mem.eql(u8, @typeName(T), concept),
        concepts.traits.hasField(T, "context"),
        concepts.traits.hasDecls(T, .{ "Ok", "Error" }),
        concepts.traits.hasFunctions(T, .{ "serializeElement", "end" }),
    });
}
