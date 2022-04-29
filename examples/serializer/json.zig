const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        Map,
        Seq,
        Map,
        serializeBool,
        serializeEnum,
        serializeNumber,
        serializeNumber,
        serializeMap,
        serializeNull,
        serializeSeq,
        serializeSome,
        serializeString,
        serializeStruct,
        serializeNull,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeEnum(self: @This(), value: anytype) !Ok {
        try self.serializeString(@tagName(value));
    }

    fn serializeMap(_: @This(), _: ?usize) !Map {
        std.debug.print("{{", .{});

        return Map{};
    }

    fn serializeNull(_: @This()) !Ok {
        std.debug.print("null", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) !Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: @This(), _: ?usize) !Seq {
        std.debug.print("[", .{});

        return Seq{};
    }

    fn serializeSome(self: @This(), value: anytype) !Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeString(_: @This(), value: anytype) !Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeStruct(self: @This(), comptime _: []const u8, len: usize) !Map {
        return try self.serializeMap(len);
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeElement,
        end,
    );

    fn serializeElement(self: *@This(), value: anytype) !void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) !Serializer.Ok {
        std.debug.print("]", .{});
    }
};

const Map = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Map(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeKey,
        serializeValue,
        end,
    );

    pub usingnamespace getty.ser.Structure(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeField,
        end,
    );

    fn serializeKey(self: *@This(), value: anytype) !void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeValue(_: *@This(), value: anytype) !void {
        std.debug.print(": ", .{});

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeField(self: *@This(), comptime key: []const u8, value: anytype) !void {
        try self.serializeKey(key);
        try self.serializeValue(value);
    }

    fn end(_: *@This()) !Serializer.Ok {
        std.debug.print("}}", .{});
    }
};
