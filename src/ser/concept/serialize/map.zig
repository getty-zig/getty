const concepts = @import("concepts");

const SerializeConcept = @import("detail/serialize.zig").SerializeConcept;

const concept = "getty.ser.MapSerialize";
const funcs = .{
    "serializeKey",
    "serializeValue",
    "serializeEntry",
    "end",
};

pub const @"getty.ser.MapSerialize" = SerializeConcept(concept, funcs);
