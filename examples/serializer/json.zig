const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Serializer,
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        Map,
        Seq,
        Map,
        serializeBool,
        serializeEnum,
        serializeFloat,
        serializeInt,
        serializeMap,
        serializeNull,
        serializeSeq,
        serializeSome,
        serializeString,
        serializeStruct,
        serializeVoid,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: Serializer, value: bool) !Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeEnum(self: Serializer, value: anytype) !Ok {
        try self.serializeString(@tagName(value));
    }

    fn serializeFloat(_: Serializer, value: anytype) !Ok {
        std.debug.print("{e}", .{value});
    }

    fn serializeInt(_: Serializer, value: anytype) !Ok {
        std.debug.print("{d}", .{value});
    }

    fn serializeMap(_: Serializer, _: ?usize) !Map {
        std.debug.print("{{", .{});

        return Map{};
    }

    fn serializeNull(_: Serializer) !Ok {
        std.debug.print("null", .{});
    }

    fn serializeSome(self: Serializer, value: anytype) !Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeSeq(_: Serializer, _: ?usize) !Seq {
        std.debug.print("[", .{});

        return Seq{};
    }

    fn serializeString(_: Serializer, value: anytype) !Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeStruct(self: Serializer, comptime _: []const u8, length: usize) !Map {
        return try self.serializeMap(length);
    }

    fn serializeVoid(self: Serializer) !Ok {
        return try self.serializeNull();
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *Seq,
        Serializer.Ok,
        Serializer.Error,
        serializeElement,
        end,
    );

    fn serializeElement(self: *Seq, value: anytype) !void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *Seq) !Serializer.Ok {
        std.debug.print("]", .{});
    }
};

const Map = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Map(
        *Map,
        Serializer.Ok,
        Serializer.Error,
        serializeKey,
        serializeValue,
        end,
    );

    pub usingnamespace getty.ser.Structure(
        *Map,
        Serializer.Ok,
        Serializer.Error,
        serializeField,
        end,
    );

    fn serializeKey(self: *Map, value: anytype) !void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeValue(_: *Map, value: anytype) !void {
        std.debug.print(": ", .{});

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeField(self: *Map, comptime key: []const u8, value: anytype) !void {
        try serializeKey(self, key);
        try serializeValue(self, value);
    }

    fn end(_: *Map) !Serializer.Ok {
        std.debug.print("}}", .{});
    }
};

pub fn main() anyerror!void {
    const values = .{
        true,
        1,
        3.14,
        "Getty!",
        .{ .foo, .bar },
        .{ .x = 1, .y = 2 },
    };

    const serializer = (Serializer{}).serializer();

    inline for (values) |value| {
        try getty.serialize(value, serializer);
        std.debug.print("\n", .{});
    }
}
