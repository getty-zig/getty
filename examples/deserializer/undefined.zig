const getty = @import("getty");

const Deserializer = struct {
    pub usingnamespace getty.Deserializer(
        @This(),
        getty.de.Error,
        getty.default_dt,
        getty.default_dt,
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
    const d = (Deserializer{}).deserializer();

    // COMPILE ERROR: `Deserializer` does not implement `deserializeBool`.
    _ = try getty.deserialize(null, bool, d);
}
