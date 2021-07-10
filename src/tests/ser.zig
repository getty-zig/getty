const std = @import("std");
const ser = @import("getty").ser;

const testing = std.testing;
const expectEqualSlices = testing.expectEqualSlices;

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

pub const Serializer = struct {
    buf: [4]Elem = .{.Undefined} ** 4,
    idx: usize = 0,

    const Self = @This();

    pub const Ok = void;
    pub const Error = std.mem.Allocator.Error;

    //pub const Map = SM;
    pub const Sequence = SI;
    pub const Struct = SS;
    //pub const Tuple = ST;

    /// Implements `getty.ser.Serializer`.
    pub const S = ser.Serializer(
        *Self,
        Ok,
        Error,
        //Map,
        Sequence,
        Struct,
        //Tuple,
        serializeBool,
        serializeFloat,
        serializeInt,
        serializeNull,
        serializeSequence,
        serializeString,
        serializeStruct,
        //serializeTuple,
        serializeVariant,
        //serializeVoid,
    );

    pub fn serializer(self: *Self) S {
        return .{ .context = self };
    }

    /// Implements `boolFn` for `getty.ser.Serializer`.
    pub fn serializeBool(self: *Self, _: bool) Error!Ok {
        self.buf[self.idx] = .Bool;
        self.idx += 1;
    }

    /// Implements `floatFn` for `getty.ser.Serializer`.
    pub fn serializeFloat(self: *Self, _: anytype) Error!Ok {
        self.buf[self.idx] = .Float;
        self.idx += 1;
    }

    /// Implements `intFn` for `getty.ser.Serializer`.
    pub fn serializeInt(self: *Self, _: anytype) Error!Ok {
        self.buf[self.idx] = .Int;
        self.idx += 1;
    }

    /// Implements `nullFn` for `getty.ser.Serializer`.
    pub fn serializeNull(self: *Self) Error!Ok {
        self.buf[self.idx] = .Null;
        self.idx += 1;
    }

    /// Implements `sequenceFn` for `getty.ser.Serializer`.
    pub fn serializeSequence(self: *Self) Error!Sequence {
        self.buf[self.idx] = .SequenceStart;
        self.idx += 1;

        return self.getSequence();
    }

    /// Implements `stringFn` for `getty.ser.Serializer`.
    pub fn serializeString(self: *Self, _: anytype) Error!Ok {
        self.buf[self.idx] = .String;
        self.idx += 1;
    }

    /// Implements `structFn` for `getty.ser.Serializer`.
    pub fn serializeStruct(self: *Self) Error!Struct {
        self.buf[self.idx] = .StructStart;
        self.idx += 1;

        return self.getStruct();
    }

    /// Implements `variantFn` for `getty.ser.Serializer`.
    pub fn serializeVariant(self: *Self, value: anytype) Error!Ok {
        _ = value;

        self.buf[self.idx] = .Variant;
        self.idx += 1;
    }

    /// Implements `getty.ser.Sequence`.
    pub const SI = ser.SequenceInterface(
        *Self,
        Ok,
        Error,
        serializeElement,
        seqEnd,
    );

    pub fn getSequence(self: *Self) SI {
        return .{ .context = self };
    }

    /// Implements `elementFn` for `getty.ser.Sequence`.
    pub fn serializeElement(self: *Self, value: anytype) Error!void {
        _ = value;

        self.buf[self.idx] = .Element;
        self.idx += 1;
    }

    /// Implements `endFn` for `getty.ser.Sequence`.
    pub fn seqEnd(self: *Self) Error!Ok {
        self.buf[self.idx] = .SequenceEnd;
        self.idx += 1;
    }

    /// Implements `getty.ser.Struct`.
    pub const SS = ser.StructInterface(
        *Self,
        Ok,
        Error,
        serializeField,
        structEnd,
    );

    pub fn getStruct(self: *Self) SS {
        return .{ .context = self };
    }

    /// Implements `fieldFn` for `getty.ser.Struct`.
    pub fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!void {
        _ = key;
        _ = value;

        self.buf[self.idx] = .Field;
        self.idx += 1;
    }

    /// Implements `endFn` for `getty.ser.Struct`.
    pub fn structEnd(self: *Self) Error!Ok {
        self.buf[self.idx] = .StructEnd;
        self.idx += 1;
    }
};

// TODO: Handle multiple serializations (e.g., .{ .Int, .Int, ... }).
test "Serialize" {
    const test_cases = [_]struct {
        name: []const u8,
        input: anytype,
        output: []const Elem,
    }{
        .{
            .name = "Boolean",
            .input = true,
            .output = &.{ .Bool, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Error value",
            .input = error.Elem,
            .output = &.{ .String, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Integer (comptime)",
            .input = 1,
            .output = &.{ .Int, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Integer (unsigned)",
            .input = @as(u8, 1),
            .output = &.{ .Int, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Integer (signed)",
            .input = @as(i8, -1),
            .output = &.{ .Int, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Null",
            .input = null,
            .output = &.{ .Null, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Optional (some)",
            .input = @as(?i8, 1),
            .output = &.{ .Int, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Optional (none)",
            .input = @as(?i8, null),
            .output = &.{ .Null, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "String literal",
            .input = "h\x65llo",
            .output = &.{ .String, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "String (byte slice)",
            .input = &[_]u8{65},
            .output = &.{ .String, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Enum (variant instance)",
            .input = enum { Foo }.Foo,
            .output = &.{ .Variant, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Enum (literal)",
            .input = .Foo,
            .output = &.{ .Variant, .Undefined, .Undefined, .Undefined },
        },
        .{
            .name = "Vector",
            .input = @splat(2, @as(u32, 1)),
            .output = &.{ .SequenceStart, .Element, .Element, .SequenceEnd },
        },
    };

    inline for (test_cases) |t| {
        var s = Serializer{};
        try ser.serialize(&s, t.input);
        try expectEqualSlices(Elem, &s.buf, t.output);
    }
}

// FIXME: Merge into test "Serialize" blocked by #5877.
test "Serialize - array" {
    var s = Serializer{};
    try ser.serialize(&s, [_]u8{ 1, 2 });
    try expectEqualSlices(Elem, &s.buf, &.{
        .SequenceStart,
        .Element,
        .Element,
        .SequenceEnd,
    });
}

// FIXME: Merge into test "Serialize" blocked by #5877.
test "Serialize - struct" {
    var s = Serializer{};
    try ser.serialize(&s, struct { x: i32, y: i32 }{ .x = 0, .y = 0 });
    try expectEqualSlices(Elem, &s.buf, &.{ .StructStart, .Field, .Field, .StructEnd });
}

// FIXME: Merge into test "Serialize" blocked by #5877.
test "Serialize - struct (custom)" {
    var s = Serializer{};

    const Point = struct {
        x: i32,
        y: i32,

        /// Skips serializing `y`.
        pub fn serialize(self: @This(), serializer: anytype) !void {
            const st = try serializer.serializeStruct();
            try st.serializeField("x", @field(self, "x"));
            try st.end();
        }
    };

    var point = Point{ .x = 1, .y = 2 };

    try ser.serialize(&s, &point);
    try expectEqualSlices(Elem, &s.buf, &.{ .StructStart, .Field, .StructEnd, .Undefined });
}

// FIXME: Merge into test "Serialize" blocked by #5877 (probably).
test "Serialize - tagged union" {
    const Union = union(enum) { Int: i32, Bool: bool };
    var s = Serializer{};
    try ser.serialize(&s, Union{ .Int = 42 });
    try ser.serialize(&s, Union{ .Bool = true });
    try expectEqualSlices(Elem, &s.buf, &.{ .Int, .Bool, .Undefined, .Undefined });
}
