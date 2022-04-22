const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        void,
        error{ Io, Syntax },
        getty.default_st,
        getty.default_st,
        @This(),
        @This(),
        @This(),
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    // COMPILE ERROR: `Serializer` does not implement `serializeBool`.
    try getty.serialize(true, s);
}
