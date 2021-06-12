const std = @import("std");
const ser = @import("getty").ser;

const testing = std.testing;
const expectEqualSlices = testing.expectEqualSlices;

pub const Serializer = struct {
    const Self = @This();

    const Elem = enum {
        Undefined,
        Bool,
        Element,
        Field,
        Float,
        Int,
        Null,
        SequenceEnd,
        SequenceStart,
        String,
        StructEnd,
        StructStart,
        Variant,
    };

    pub const Ok = void;
    pub const Error = std.mem.Allocator.Error;

    pub const S = ser.Serializer(
        *Self,
        Ok,
        Error,
        serializeBool,
        serializeElement,
        serializeField,
        serializeFloat,
        serializeInt,
        serializeNull,
        serializeSequence,
        serializeString,
        serializeStruct,
        serializeVariant,
    );

    buf: [4]Elem = .{.Undefined} ** 4,
    idx: usize = 0,

    pub fn serializer(self: *Self) S {
        return .{ .context = self };
    }

    pub fn serializeBool(self: *Self, value: bool) Error!Ok {
        self.buf[self.idx] = .Bool;
        self.idx += 1;
    }

    pub fn serializeElement(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Element;
        self.idx += 1;
    }

    pub fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!Ok {
        self.buf[self.idx] = .Field;
        self.idx += 1;
    }

    pub fn serializeFloat(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Float;
        self.idx += 1;
    }

    pub fn serializeInt(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Int;
        self.idx += 1;
    }

    pub fn serializeNull(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Null;
        self.idx += 1;
    }

    pub fn serializeSequence(self: *Self) Error!fn (*Self) Error!Ok {
        self.buf[self.idx] = .SequenceStart;
        self.idx += 1;

        return struct {
            pub fn end(s: *Self) Error!Ok {
                s.buf[s.idx] = .SequenceEnd;
                s.idx += 1;
            }
        }.end;
    }

    pub fn serializeString(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .String;
        self.idx += 1;
    }

    pub fn serializeStruct(self: *Self) Error!fn (*Self) Error!Ok {
        self.buf[self.idx] = .StructStart;
        self.idx += 1;

        return struct {
            pub fn end(s: *Self) Error!Ok {
                s.buf[s.idx] = .StructEnd;
                s.idx += 1;
            }
        }.end;
    }

    pub fn serializeVariant(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Variant;
        self.idx += 1;
    }
};

test "Serialize - array" {
    var s = Serializer{};
    try ser.serialize(&s, [_]u8{ 1, 2 });
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .SequenceStart,
        .Element,
        .Element,
        .SequenceEnd,
    });
}

test "Serialize - bool" {
    var s = Serializer{};
    try ser.serialize(&s, true);
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .Bool,
        .Undefined,
        .Undefined,
        .Undefined,
    });
}

test "Serialize - error set" {
    var s = Serializer{};
    try ser.serialize(&s, error.Elem);
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .String,
        .Undefined,
        .Undefined,
        .Undefined,
    });
}

test "Serialize - integer" {
    var s = Serializer{};
    try ser.serialize(&s, 1);
    try ser.serialize(&s, @as(u8, 1));
    try ser.serialize(&s, @as(i8, 1));
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .Int,
        .Int,
        .Int,
        .Undefined,
    });
}

test "Serialize - null" {
    var s = Serializer{};
    try ser.serialize(&s, null);
    try expectEqualSlices(Serializer.Elem, s.buf[0..1], &.{.Null});
}

test "Serialize - optional" {
    var s = Serializer{};
    try ser.serialize(&s, @as(?i8, 1));
    try ser.serialize(&s, @as(?i8, null));
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .Int,
        .Null,
        .Undefined,
        .Undefined,
    });
}

test "Serialize - string" {
    var s = Serializer{};
    try ser.serialize(&s, "h\x65llo");
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .String,
        .Undefined,
        .Undefined,
        .Undefined,
    });
}

test "Serialize - struct" {
    var s = Serializer{};
    try ser.serialize(&s, struct { x: i32, y: i32 }{ .x = 0, .y = 0 });
    try expectEqualSlices(Serializer.Elem, s.buf[0..4], &.{
        .StructStart,
        .Field,
        .Field,
        .StructEnd,
    });
}

test "Serialize - struct (custom)" {
    var s = Serializer{};

    const Point = struct {
        pub fn serialize(self: @This(), serializer: anytype) !void {
            var end = try serializer.serializeStruct();
            try serializer.serializeField("x", @field(self, "x"));
            return end(serializer);
        }

        x: i32,
        y: i32,
    };

    var point = Point{ .x = 1, .y = 2 };

    try ser.serialize(&s, &point);
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .StructStart,
        .Field,
        .StructEnd,
        .Undefined,
    });
}

test "Serialize - tagged union" {
    const Union = union(enum) { Int: i32, Bool: bool };
    var s = Serializer{};
    try ser.serialize(&s, Union{ .Int = 42 });
    try ser.serialize(&s, Union{ .Bool = true });
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .Int,
        .Bool,
        .Undefined,
        .Undefined,
    });
}

test "Serialize - enum" {
    var s = Serializer{};
    try ser.serialize(&s, enum { Foo }.Foo);
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .Variant,
        .Undefined,
        .Undefined,
        .Undefined,
    });
}

test "Serialize - enum literal" {
    var s = Serializer{};
    try ser.serialize(&s, .Foo);
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .Variant,
        .Undefined,
        .Undefined,
        .Undefined,
    });
}

test "Serialize - vector" {
    var s = Serializer{};
    try ser.serialize(&s, @splat(2, @as(u32, 1)));
    try expectEqualSlices(Serializer.Elem, &s.buf, &.{
        .SequenceStart,
        .Element,
        .Element,
        .SequenceEnd,
    });
}
