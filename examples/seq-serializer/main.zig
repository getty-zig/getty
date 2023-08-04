const std = @import("std");
const getty = @import("getty");

const page_ally = std.heap.page_allocator;

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Serializer,
        Ok,
        Error,
        null,
        null,
        null,
        Seq,
        null,
        .{
            .serializeBool = serializeBool,
            .serializeSeq = serializeSeq,
        },
    );

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: Serializer, value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: Serializer, _: ?usize) Error!Seq {
        std.debug.print("[", .{});
        return Seq{};
    }

    const Seq = struct {
        first: bool = true,

        pub usingnamespace getty.ser.Seq(
            *Seq,
            Ok,
            Error,
            .{
                .serializeElement = serializeElement,
                .end = end,
            },
        );

        fn serializeElement(self: *Seq, value: anytype) Error!void {
            switch (self.first) {
                true => self.first = false,
                false => std.debug.print(", ", .{}),
            }

            try getty.serialize(null, value, (Serializer{}).serializer());
        }

        fn end(_: *Seq) Error!Ok {
            std.debug.print("]\n", .{});
        }
    };
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    // Primitives
    try getty.serialize(null, .{ true, false }, s);
    try getty.serialize(null, [_]bool{ true, false }, s);
    try getty.serialize(null, &&&[_]bool{ true, false }, s);
    try getty.serialize(null, @Vector(2, bool){ true, false }, s);

    // std.ArrayList
    var list = std.ArrayList(bool).init(page_ally);
    defer list.deinit();
    try list.appendSlice(&.{ true, false });
    try getty.serialize(null, list, s);

    // std.BoundedArray
    var arr = try std.BoundedArray(bool, 2).fromSlice(&.{ true, false });
    try getty.serialize(null, arr, s);
}
