const std = @import("std");
const ser = @import("getty").ser;

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

    pub fn getSerializer(self: *Self) S {
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
    pub fn serializeSequence(self: *Self, length: ?usize) Error!Sequence {
        _ = length;

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

    /// Implements `getty.ser.SerializeSequence`.
    pub const SI = ser.SerializeSequence(
        *Self,
        Ok,
        Error,
        serializeElement,
        seqEnd,
    );

    pub fn getSequence(self: *Self) SI {
        return .{ .context = self };
    }

    /// Implements `elementFn` for `getty.ser.SerializeSequence`.
    pub fn serializeElement(self: *Self, value: anytype) Error!void {
        _ = value;

        self.buf[self.idx] = .Element;
        self.idx += 1;
    }

    /// Implements `endFn` for `getty.ser.SerializeSequence`.
    pub fn seqEnd(self: *Self) Error!Ok {
        self.buf[self.idx] = .SequenceEnd;
        self.idx += 1;
    }

    /// Implements `getty.ser.SerializeStruct`.
    pub const SS = ser.SerializeStruct(
        *Self,
        Ok,
        Error,
        serializeField,
        structEnd,
    );

    pub fn getStruct(self: *Self) SS {
        return .{ .context = self };
    }

    /// Implements `fieldFn` for `getty.ser.SerializeStruct`.
    pub fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!void {
        _ = key;
        _ = value;

        self.buf[self.idx] = .Field;
        self.idx += 1;
    }

    /// Implements `endFn` for `getty.ser.SerializeStruct`.
    pub fn structEnd(self: *Self) Error!Ok {
        self.buf[self.idx] = .StructEnd;
        self.idx += 1;
    }
};

test "Array" {
    try t([_]i8{ 1, 2 }, &.{ .SequenceStart, .Element, .Element, .SequenceEnd });
}

test "Boolean" {
    try t(true, &.{ .Bool, .Undefined, .Undefined, .Undefined });
    try t(false, &.{ .Bool, .Undefined, .Undefined, .Undefined });
}

test "Enum" {
    try t(enum { Foo }.Foo, &.{ .Variant, .Undefined, .Undefined, .Undefined });
    try t(.Foo, &.{ .Variant, .Undefined, .Undefined, .Undefined });
}

test "Error value" {
    try t(error.Elem, &.{ .String, .Undefined, .Undefined, .Undefined });
}

test "Integer" {
    try t(1, &.{ .Int, .Undefined, .Undefined, .Undefined });
    try t(@as(u8, 1), &.{ .Int, .Undefined, .Undefined, .Undefined });
    try t(@as(i8, -1), &.{ .Int, .Undefined, .Undefined, .Undefined });
}

test "Optional" {
    try t(@as(?bool, true), &.{ .Bool, .Undefined, .Undefined, .Undefined });
    try t(@as(?bool, null), &.{ .Null, .Undefined, .Undefined, .Undefined });
}

test "String" {
    try t("h\x65llo", &.{ .String, .Undefined, .Undefined, .Undefined });
    try t(&[_]u8{65}, &.{ .String, .Undefined, .Undefined, .Undefined });
}

test "Struct" {
    const A = struct {
        x: i32,
        y: i32,
    };

    const B = struct {
        x: i32,
        y: i32,

        /// Skips serializing `y`.
        pub fn serialize(self: @This(), serializer: anytype) !void {
            const st = try serializer.serializeStruct();
            try st.serializeField("x", @field(self, "x"));
            try st.end();
        }
    };

    const a = A{ .x = 0, .y = 0 };
    const b = B{ .x = 0, .y = 0 };

    try t(a, &.{ .StructStart, .Field, .Field, .StructEnd });
    try t(b, &.{ .StructStart, .Field, .StructEnd, .Undefined });
}

test "Tagged union" {
    const Union = union(enum) { Int: u8, Bool: bool };

    try t(Union{ .Int = 0 }, &.{ .Int, .Undefined, .Undefined, .Undefined });
    try t(Union{ .Bool = true }, &.{ .Bool, .Undefined, .Undefined, .Undefined });
}

test "Vector" {
    try t(@splat(2, @as(u32, 1)), &.{ .SequenceStart, .Element, .Element, .SequenceEnd });
}

fn t(input: anytype, output: []const Elem) !void {
    var s = Serializer{};
    try ser.serialize(&s, input);

    try std.testing.expectEqualSlices(Elem, &s.buf, output);
}

comptime {
    std.testing.refAllDecls(@This());
}
