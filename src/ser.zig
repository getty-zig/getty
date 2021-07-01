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
    comptime variantFn: fn (context: Context, value: anytype) E!O,
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
        // Serialize an enum value.
        pub fn serializeVariant(self: Self, value: anytype) Error!Ok {
            return try variantFn(self.context, value);
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
                    if (comptime trait.isZigString(T)) {
                        break :blk try s.serializeString(value);
                    } else {
                        const end = try s.serializeSequence();
                        for (value) |v| {
                            try s.serializeElement(v);
                        }
                        break :blk try end(serializer);
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

                const end = try s.serializeStruct();
                inline for (info.fields) |field| {
                    try s.serializeField(field.name, @field(value, field.name));
                }
                return try end(serializer);
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
