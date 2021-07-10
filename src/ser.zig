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
///   - Implementations of all required methods.
///
/// Note that while many required methods take values of `anytype`, due to the
/// checks performed in `serialize`, implementations have compile-time
/// guarantees that the passed-in value is of a type one would naturally
/// expect.
///
/// Data model:
///
///     1. bool
///     2. integer
///     3. float
///     4. string
///     5. option
///     6. void
///     7. variant
///     8. sequence
///     9. map
///     10. struct
///     11. tuple
pub fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    // comptime MapType: type,
    comptime SequenceType: type,
    comptime StructType: type,
    // comptime TupleType: type,
    comptime boolFn: fn (context: Context, value: bool) E!O,
    comptime floatFn: fn (context: Context, value: anytype) E!O,
    comptime intFn: fn (context: Context, value: anytype) E!O,
    // comptime mapFn: fn (context: Context, value: anytype) E!MapType,
    comptime nullFn: fn (context: Context) E!O,
    comptime sequenceFn: fn (context: Context) E!SequenceType,
    comptime stringFn: fn (context: Context, value: anytype) E!O,
    comptime structFn: fn (context: Context) E!StructType,
    // comptime tupleFn: fn (context: Context, value: anytype) E!TupleType,
    comptime variantFn: fn (context: Context, value: anytype) E!O,
    // comptime voidFn: fn (context: Context) E!O,
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        //pub const Map = MapType;
        pub const Sequence = SequenceType;
        pub const Struct = StructType;
        //pub const Tuple = TupleType;

        /// Serialize a boolean value.
        pub fn serializeBool(self: Self, value: bool) Error!Ok {
            return try boolFn(self.context, value);
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
        pub fn serializeNull(self: Self) Error!Ok {
            return try nullFn(self.context);
        }

        /// Serialize a variably sized heterogeneous sequence of values.
        pub fn serializeSequence(self: Self) Error!Sequence {
            return try sequenceFn(self.context);
        }

        /// Serialize a string value.
        pub fn serializeString(self: Self, value: anytype) Error!Ok {
            return try stringFn(self.context, value);
        }

        // Serialize a struct value.
        pub fn serializeStruct(self: Self) Error!Struct {
            return try structFn(self.context);
        }

        // Serialize an enum value.
        pub fn serializeVariant(self: Self, value: anytype) Error!Ok {
            return try variantFn(self.context, value);
        }
    };
}

pub fn SequenceInterface(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime elementFn: fn (context: Context, value: anytype) E!void,
    comptime endFn: fn (context: Context) E!O,
) type {
    return struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a sequence element.
        pub fn serializeElement(self: Self, value: anytype) Error!void {
            try elementFn(self.context, value);
        }

        /// Finish serializing a sequence.
        pub fn end(self: Self) Error!Ok {
            return try endFn(self.context);
        }
    };
}

pub fn StructInterface(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime fieldFn: fn (context: Context, comptime key: []const u8, value: anytype) E!void,
    comptime endFn: fn (context: Context) E!O,
) type {
    return struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a struct field.
        pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) Error!void {
            try fieldFn(self.context, key, value);
        }

        /// Finish serializing a struct.
        pub fn end(self: Self) Error!Ok {
            return try endFn(self.context);
        }
    };
}

/// Serializes values that are of a type supported by Getty.
pub fn serialize(serializer: anytype, value: anytype) switch (@typeInfo(@TypeOf(serializer))) {
    .Pointer => |info| info.child.Error!info.child.Ok,
    else => @compileError("expected pointer to serializer, found " ++ @typeName(T)),
} {
    const T = @TypeOf(value);
    const s = serializer.serializer();

    switch (@typeInfo(T)) {
        .Array => {
            var seq = try s.serializeSequence();
            for (value) |elem| {
                try seq.serializeElement(elem);
            }
            try seq.end();
        },
        .Bool => {
            return try s.serializeBool(value);
        },
        .Enum, .EnumLiteral => {
            return if (comptime trait.hasFn("serialize")(T))
                try value.serialize(serializer)
            else
                try s.serializeVariant(value);
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
            return try s.serializeNull();
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
                    if (comptime trait.isZigString(T)) {
                        break :blk try s.serializeString(value);
                    } else {
                        var seq = try s.serializeSequence();
                        for (value) |elem| {
                            try seq.serializeElement(elem);
                        }
                        try seq.end();
                    }
                },
                else => @compileError("unsupported serialize type: " ++ @typeName(T)),
            };
        },
        .Struct => |info| {
            if (comptime trait.hasFn("serialize")(T)) {
                return try value.serialize(serializer);
            } else {
                // TODO: coerce this to @TypeOf(_getty_attributes)
                //const attributes = if (comptime trait.hasDecls(T, .{"_getty_attributes"})) T._getty_attributes else null;

                const st = try s.serializeStruct();
                inline for (info.fields) |field| {
                    try st.serializeField(field.name, @field(value, field.name));
                }
                try st.end();
            }
        },
        .Union => |info| {
            if (comptime trait.hasFn("serialize")(T)) {
                return try value.serialize(serializer);
            } else {
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
            }
        },
        .Vector => |info| {
            return try serialize(serializer, @as([info.len]info.child, value));
        },
        else => @compileError("unsupported serialize type: " ++ @typeName(T)),
    }
}

comptime {
    std.testing.refAllDecls(@This());
}
