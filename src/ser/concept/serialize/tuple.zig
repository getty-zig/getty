const concepts = @import("concepts");

const SerializeConcept = @import("detail/serialize.zig").SerializeConcept;

const concept = "getty.ser.TupleSerialize";
const funcs = .{
    "serializeElement",
    "end",
};

pub const @"getty.ser.TupleSerialize" = SerializeConcept(concept, funcs);
