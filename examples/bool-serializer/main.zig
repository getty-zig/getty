const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Serializer,
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{
            .serializeBool = serializeBool,
        },
    );

    const Ok = void;
    const Error = error{};

    fn serializeBool(_: Serializer, value: bool) Error!Ok {
        std.debug.print("{}\n", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);
    try getty.serialize(false, s);
}
