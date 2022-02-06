const std = @import("std");

const concepts = @import("concepts");

const concept = "getty.Serializer";

pub fn @"getty.Serializer"(comptime T: type) void {
    comptime concepts.Concept(concept, "")(.{
        std.mem.eql(u8, @typeName(T), concept),
        concepts.traits.hasField(T, "context"),
        concepts.traits.hasDecls(T, .{
            "Ok",
            "Error",
            "st",
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
            "serializeTuple",
            "serializeVoid",
        }),
    });
}
