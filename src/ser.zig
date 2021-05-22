const std = @import("std");

const trait = std.meta.trait;
const unicode = std.unicode;

fn SerializerErrorUnion(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Pointer => @typeInfo(T).Pointer.child.Error!@typeInfo(T).Pointer.child.Ok,
        else => @compileError("expected pointer to serializer, found " ++ @typeName(T)),
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
pub fn serialize(serializer: anytype, value: anytype) SerializerErrorUnion(@TypeOf(serializer)) {
    const T = @TypeOf(value);
    const s = serializer.serializer();

    switch (@typeInfo(T)) {
        .Array => return try s.serializeSequence(value),
        .Bool => return try s.serializeBool(value),
        //.Enum => {},
        .ErrorSet => return try serialize(serializer, @as([]const u8, @errorName(value))),
        .Float, .ComptimeFloat => return try s.serializeFloat(value),
        .Int, .ComptimeInt => return try s.serializeInt(value),
        .Null => return try s.serializeNull(value),
        .Optional => return if (value) |v| try serialize(serializer, v) else try serialize(serializer, null),
        .Pointer => |info| return switch (info.size) {
            .One => switch (@typeInfo(info.child)) {
                .Array => try serialize(serializer, @as([]const std.meta.Elem(info.child), value)),
                else => try serialize(serializer, value.*),
            },
            .Slice => blk: {
                if (trait.isZigString(T) and unicode.utf8ValidateSlice(value)) {
                    break :blk try s.serializeString(value);
                } else {
                    break :blk try s.serializeSequence(value);
                }
            },
            else => @compileError("unsupported serialize type: " ++ @typeName(T)),
        },
        //.Struct => |S| {},
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
        .Vector => |info| return try s.serializeSequence(@as([info.len]info.child, value)),
        else => @compileError("unsupported serialize type: " ++ @typeName(T)),
    }
}

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
    comptime intFn: fn (context: Context, value: anytype) E!O,
    comptime floatFn: fn (context: Context, value: anytype) E!O,
    comptime nullFn: fn (context: Context, value: anytype) E!O,
    comptime stringFn: fn (context: Context, value: anytype) E!O,
    comptime sequenceFn: fn (context: Context, value: anytype) E!O,
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

        /// Serialize an integer value.
        pub fn serializeInt(self: Self, value: anytype) Error!Ok {
            return try intFn(self.context, value);
        }

        /// Serialize a float value.
        pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
            return try floatFn(self.context, value);
        }

        /// Serialize a null value.
        pub fn serializeNull(self: Self, value: anytype) Error!Ok {
            return try nullFn(self.context, value);
        }

        /// Serialize a string value.
        pub fn serializeString(self: Self, value: anytype) Error!Ok {
            return try stringFn(self.context, value);
        }

        /// Serialize a variably sized heterogeneous sequence of values.
        ///
        /// Implementations are typically structured as follows:
        ///
        ///   1. Start with a prefix character suited for the type being serialized.
        ///   2. Serialize the elements of the sequence.
        ///   3. End with a suffix character suited for the type being serialized.
        pub fn serializeSequence(self: Self, value: anytype) Error!Ok {
            return try sequenceFn(self.context, value);
        }
    };
}

const eql = std.mem.eql;
const expect = std.testing.expect;

const TestSerializer = struct {
    const Self = @This();

    pub const Ok = []const u8;
    pub const Error = error{Error};

    pub const S = Serializer(
        *Self,
        Ok,
        Error,
        serializeBool,
        serializeInt,
        serializeFloat,
        serializeNull,
        serializeString,
        serializeSequence,
    );

    pub fn serializer(self: *Self) S {
        return .{ .context = self };
    }

    pub fn serializeBool(self: *Self, value: bool) Error!Ok {
        return "bool";
    }

    pub fn serializeInt(self: *Self, value: anytype) Error!Ok {
        return "int";
    }

    pub fn serializeFloat(self: *Self, value: anytype) Error!Ok {
        return "float";
    }

    pub fn serializeNull(self: *Self, value: anytype) Error!Ok {
        return "null";
    }

    pub fn serializeString(self: *Self, value: anytype) Error!Ok {
        return "string";
    }

    pub fn serializeSequence(self: *Self, value: anytype) Error!Ok {
        return "sequence";
    }
};

test "serialize - array" {
    var serializer = TestSerializer{};
    const result = try serialize(&serializer, [_]u8{ 'A', 'B', 'C' });

    try expect(eql(u8, result, "sequence"));
}

test "serialize - bool" {
    var serializer = TestSerializer{};

    for (&[_]bool{ true, false }) |b| {
        const result = try serialize(&serializer, b);
        try expect(eql(u8, result, "bool"));
    }
}

test "Serialize - error set" {
    var serializer = TestSerializer{};
    const result = try serialize(&serializer, error{Error}.Error);

    try expect(eql(u8, result, "string"));
}

test "Serialize - integer" {
    var serializer = TestSerializer{};

    comptime var bits = 0;
    inline while (bits < 64) : (bits += 1) {
        const Signed = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = bits } });
        const Unsigned = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = bits } });

        inline for (&[_]type{ Signed, Unsigned }) |T| {
            const max = std.math.maxInt(T);
            const min = std.math.minInt(T);

            var max_buf: [20]u8 = undefined;
            var min_buf: [20]u8 = undefined;
            const max_expected = std.fmt.bufPrint(&max_buf, "{}", .{max}) catch unreachable;
            const min_expected = std.fmt.bufPrint(&min_buf, "{}", .{min}) catch unreachable;

            const max_result = try serialize(&serializer, @as(T, max));
            const min_result = try serialize(&serializer, @as(T, min));

            try expect(eql(u8, max_result, "int"));
            try expect(eql(u8, min_result, "int"));
        }
    }
}

test "Serialize - null" {
    var serializer = TestSerializer{};
    var result = try serialize(&serializer, null);

    try expect(eql(u8, result, "null"));
}

test "Serialize - optional" {
    var serializer = TestSerializer{};

    const some: ?i8 = 1;
    const none: ?i8 = null;

    const some_result = try serialize(&serializer, some);
    const none_result = try serialize(&serializer, none);

    try expect(eql(u8, some_result, "int"));
    try expect(eql(u8, none_result, "null"));
}

test "Serialize - string" {
    var serializer = TestSerializer{};
    const result = try serialize(&serializer, "ABC");

    try expect(eql(u8, result, "string"));
}

test "Serialize - tagged union" {
    var serializer = TestSerializer{};

    const Union = union(enum) { int: i32, boolean: bool };
    var int_union = Union{ .int = 42 };
    var bool_union = Union{ .boolean = true };
    const int_result = try serialize(&serializer, int_union);
    const bool_result = try serialize(&serializer, bool_union);

    try expect(eql(u8, int_result, "int"));
    try expect(eql(u8, bool_result, "bool"));
}

test "Serialize - vector" {
    var serializer = TestSerializer{};
    const result = try serialize(&serializer, @splat(2, @as(u32, 1)));

    try expect(eql(u8, result, "sequence"));
}
