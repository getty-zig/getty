const concepts = @import("concepts");

const SerializeConcept = @import("detail/serialize.zig").SerializeConcept;

const concept = "getty.ser.SequenceSerialize";
const funcs = .{
    "serializeElement",
    "end",
};

pub const @"getty.ser.SequenceSerialize" = SerializeConcept(concept, funcs);
