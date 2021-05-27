const std = @import("std");

const trait = std.meta.trait;

/// A data format that can serialize any data type supported by Getty.
///
/// To implement the interface, the following must be provided within your
/// struct:
///
///   - An `Ok` declaration representing the successful return type of your
///     serialization functions.
///
///   - An `Error` declaration representing the error set in the return type of
///     your serialization functions.
///
///   - A `serialize` function of type `fn(*@This()) Serializer` that returns a
///     struct instance of the type returned from this interface function, with
///     `context` set to the implementation instance passed in.
///
///   - Implementations of any required methods.
///
/// Note that while many required methods take values of `anytype`, due to the
/// checks performed in `serialize`, implementations have compile-time
/// guarantees that the passed-in value is of a type one would naturally
/// expect.
pub fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime boolFn: fn (context: Context, value: bool) E!O,
    comptime elementFn: fn (context: Context, value: anytype) E!O,
    comptime fieldFn: fn (context: Context, comptime key: []const u8, value: anytype) E!O,
    comptime floatFn: fn (context: Context, value: anytype) E!O,
    comptime intFn: fn (context: Context, value: anytype) E!O,
    comptime nullFn: fn (context: Context, value: anytype) E!O,
    comptime sequenceFn: fn (context: Context) E!fn (Context) E!O,
    comptime stringFn: fn (context: Context, value: anytype) E!O,
    comptime structFn: fn (context: Context) E!fn (Context) E!O,
) type {
    return struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a boolean value.
        pub fn serializeBool(self: Self, value: bool) Error!Ok {
            return try boolFn(self.context, value);
        }

        /// Serialize a sequence element value.
        pub fn serializeElement(self: Self, value: anytype) Error!Ok {
            return try elementFn(self.context, value);
        }

        /// Serialize a struct field value.
        pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) Error!Ok {
            return try fieldFn(self.context, key, value);
        }

        /// Serialize a float value.
        pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
            return try floatFn(self.context, value);
        }

        /// Serialize an integer value.
        pub fn serializeInt(self: Self, value: anytype) Error!Ok {
            return try intFn(self.context, value);
        }

        /// Serialize a null value.
        pub fn serializeNull(self: Self, value: anytype) Error!Ok {
            return try nullFn(self.context, value);
        }

        /// Serialize a variably sized heterogeneous sequence of values.
        pub fn serializeSequence(self: Self) Error!fn (Context) Error!Ok {
            return try sequenceFn(self.context);
        }

        /// Serialize a string value.
        pub fn serializeString(self: Self, value: anytype) Error!Ok {
            return try stringFn(self.context, value);
        }

        // Serialize a struct value.
        pub fn serializeStruct(self: Self) Error!fn (Context) Error!Ok {
            return try structFn(self.context);
        }
    };
}

/// Serializes values that are of a type supported by Getty.
///
/// The types that make up the Getty data model are:
///
///  - Primitives
///    - bool
///    - float
///    - integer
///  - Non-primitives
///    - array
///    - enum
///    - error set
///    - null
///    - optional
///    - pointer (one, slice)
///    - struct
///    - tagged union
///    - vector
pub fn serialize(serializer: anytype, value: anytype) switch (@typeInfo(@TypeOf(serializer))) {
    .Pointer => |info| info.child.Error!info.child.Ok,
    else => @compileError("expected pointer to serializer, found " ++ @typeName(T)),
} {
    const T = @TypeOf(value);
    const s = serializer.serializer();

    switch (@typeInfo(T)) {
        .Array => {
            const end = try s.serializeSequence();
            for (value) |v| {
                try s.serializeElement(v);
            }
            return try end(serializer);
        },
        .Bool => {
            return try s.serializeBool(value);
        },
        .Enum => {
            @compileError("TODO: enums");
        },
        .ErrorSet => {
            return try serialize(serializer, @as([]const u8, @errorName(value)));
        },
        .Float, .ComptimeFloat => {
            return try s.serializeFloat(value);
        },
        .Int, .ComptimeInt => {
            return try s.serializeInt(value);
        },
        .Null => {
            return try s.serializeNull(value);
        },
        .Optional => {
            return if (value) |v| try serialize(serializer, v) else try serialize(serializer, null);
        },
        .Pointer => |info| {
            return switch (info.size) {
                .One => switch (@typeInfo(info.child)) {
                    .Array => try serialize(serializer, @as([]const std.meta.Elem(info.child), value)),
                    else => try serialize(serializer, value.*),
                },
                .Slice => blk: {
                    if ((comptime trait.isZigString(T)) and std.unicode.utf8ValidateSlice(value)) {
                        break :blk try s.serializeString(value);
                    }

                    const end = try s.serializeSequence();
                    for (value) |v| {
                        try s.serializeElement(v);
                    }
                    break :blk try end(serializer);
                },
                else => @compileError("unsupported serialize type: " ++ @typeName(T)),
            };
        },
        .Struct => |info| {
            if (comptime trait.hasFn("serialize")(T)) {
                return try value.serialize(serializer);
            }

            // TODO: coerce this to @TypeOf(_getty_attributes)
            const attributes = if (comptime trait.hasDecls(T, .{"_getty_attributes"})) T._getty_attributes else null;

            const end = try s.serializeStruct();
            inline for (info.fields) |field| {
                try s.serializeField(field.name, @field(value, field.name));
            }
            return try end(serializer);
        },
        .Union => |info| {
            if (comptime trait.hasFn("serialize")(T)) {
                return try value.serialize(serializer);
            }

            if (info.tag_type) |Tag| {
                inline for (info.fields) |field| {
                    if (@field(Tag, field.name) == value) {
                        return try serialize(serializer, @field(value, field.name));
                    }
                }

                // UNREACHABLE: Since we go over every field in the union, we
                // always find the field that matches the passed-in value.
                unreachable;
            } else {
                @compileError("unsupported serialize type: Untagged " ++ @typeName(T));
            }
        },
        .Vector => |info| {
            return try serialize(serializer, @as([info.len]info.child, value));
        },
        else => @compileError("unsupported serialize type: " ++ @typeName(T)),
    }
}

const expectEqualSlices = std.testing.expectEqualSlices;

test "Serialize - array" {
    var s = TestSerializer{};
    try serialize(&s, [_]u8{ 1, 2 });
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..4], &.{ .SequenceStart, .Element, .Element, .SequenceEnd });
}

test "Serialize - bool" {
    var s = TestSerializer{};
    try serialize(&s, true);
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..1], &.{.Bool});
}

test "Serialize - error set" {
    var s = TestSerializer{};
    try serialize(&s, error.Elem);
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..1], &.{.String});
}

test "Serialize - integer" {
    var s = TestSerializer{};
    try serialize(&s, 1);
    try serialize(&s, @as(u8, 1));
    try serialize(&s, @as(i8, 1));
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..3], &.{ .Int, .Int, .Int });
}

test "Serialize - null" {
    var s = TestSerializer{};
    try serialize(&s, null);
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..1], &.{.Null});
}

test "Serialize - optional" {
    var s = TestSerializer{};
    try serialize(&s, @as(?i8, 1));
    try serialize(&s, @as(?i8, null));
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..2], &.{ .Int, .Null });
}

test "Serialize - string" {
    var s = TestSerializer{};
    try serialize(&s, "A");
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..1], &.{.String});
}

test "Serialize - struct" {
    var s = TestSerializer{};
    try serialize(&s, struct { x: i32, y: i32 }{ .x = 0, .y = 0 });
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..4], &.{ .StructStart, .Field, .Field, .StructEnd });
}

test "Serialize - struct (custom)" {
    var s = TestSerializer{};

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

    try serialize(&s, &point);
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..3], &.{ .StructStart, .Field, .StructEnd });
}

test "Serialize - tagged union" {
    const Union = union(enum) { Int: i32, Bool: bool };
    var s = TestSerializer{};
    try serialize(&s, Union{ .Int = 42 });
    try serialize(&s, Union{ .Bool = true });
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..2], &.{ .Int, .Bool });
}

test "Serialize - vector" {
    var s = TestSerializer{};
    try serialize(&s, @splat(2, @as(u32, 1)));
    try expectEqualSlices(TestSerializer.Elem, s.buf[0..4], &.{ .SequenceStart, .Element, .Element, .SequenceEnd });
}

const TestSerializer = struct {
    const Self = @This();

    // TODO: Update naming convention (pascal is deprecated)
    const Elem = enum {
        None,
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
    };

    const Ok = void;
    const Error = std.mem.Allocator.Error;

    const S = Serializer(
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
    );

    buf: [4]Elem = undefined,
    idx: usize = 0,

    fn serializer(self: *Self) S {
        return .{ .context = self };
    }

    fn serializeBool(self: *Self, value: bool) Error!Ok {
        self.buf[self.idx] = .Bool;
        self.idx += 1;
    }

    fn serializeElement(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Element;
        self.idx += 1;
    }

    fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!Ok {
        self.buf[self.idx] = .Field;
        self.idx += 1;
    }

    fn serializeFloat(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Float;
        self.idx += 1;
    }

    fn serializeInt(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Int;
        self.idx += 1;
    }

    fn serializeNull(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .Null;
        self.idx += 1;
    }

    fn serializeSequence(self: *Self) Error!fn (*Self) Error!Ok {
        self.buf[self.idx] = .SequenceStart;
        self.idx += 1;

        return struct {
            pub fn end(s: *Self) Error!Ok {
                s.buf[s.idx] = .SequenceEnd;
                s.idx += 1;
            }
        }.end;
    }

    fn serializeString(self: *Self, value: anytype) Error!Ok {
        self.buf[self.idx] = .String;
        self.idx += 1;
    }

    fn serializeStruct(self: *Self) Error!fn (*Self) Error!Ok {
        self.buf[self.idx] = .StructStart;
        self.idx += 1;

        return struct {
            pub fn end(s: *Self) Error!Ok {
                s.buf[s.idx] = .StructEnd;
                s.idx += 1;
            }
        }.end;
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
