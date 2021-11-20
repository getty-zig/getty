const concepts = @import("concepts");

const SerializeConcept = @import("detail/serialize.zig").SerializeConcept;

const concept = "getty.ser.StructSerialize";
const funcs = .{
    "serializeField",
    "end",
};

pub const @"getty.ser.StructSerialize" = SerializeConcept(concept, funcs);
