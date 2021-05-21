const std = @import("std");

pub fn serialize(serializer: anytype, v: anytype) @typeInfo(@TypeOf(serializer)).Pointer.child.Error!@typeInfo(@TypeOf(serializer)).Pointer.child.Ok {
    const T = @TypeOf(v);
    const s = serializer.serializer();

    switch (@typeInfo(T)) {
        .Array => {
            return try serialize(serializer, &v);
        },
        .Bool => {
            return try s.serializeBool(v);
        },
        //.Enum => {},
        .ErrorSet => {
            return try serialize(serializer, @as([]const u8, @errorName(v)));
        },
        .Float, .ComptimeFloat => {
            return try s.serializeFloat(v);
        },
        .Int, .ComptimeInt => {
            return try s.serializeInt(v);
        },
        .Null => {
            return try s.serializeNull(v);
        },
        .Optional => {
            if (v) |payload| {
                return try serialize(serializer, payload);
            } else {
                return try serialize(serializer, null);
            }
        },
        .Pointer => |info| {
            return switch (info.size) {
                .One => switch (@typeInfo(info.child)) {
                    .Array => try serialize(serializer, @as([]const std.meta.Elem(info.child), v)),
                    else => try serialize(serializer, v.*),
                },
                .Slice => blk: {
                    break :blk if (info.child == u8 and std.meta.trait.isZigString(T) and std.unicode.utf8ValidateSlice(v)) {
                        try s.serializeString(v);
                    } else {
                        try s.serializeSequence(v);
                    };
                },
                else => @compileError("unsupported serialize type: " ++ @typeName(T)),
            };
        },
        //.Struct => |S| {},
        .Union => |info| {
            if (comptime std.meta.trait.hasFn("serialize")(T)) {
                return try v.serialize(serializer);
            }

            if (info.tag_type) |Tag| {
                inline for (info.fields) |field| {
                    if (@field(Tag, field.name) == v) {
                        return try serialize(serializer, @field(v, field.name));
                    }
                }
            } else {
                @compileError("unsupported serialize type: Untagged " ++ @typeName(T));
            }
        },
        .Vector => |info| {
            const array: [info.len]info.child = v;
            return try serialize(serializer, &array);
        },
        else => @compileError("unsupported serialize type: " ++ @typeName(T)),
    }
}

/// A data format that can serialize any data structure supported by Getty.
///
/// The interface defines the serialization half of the [Getty data model],
/// which is a way to categorize every Zig data structure into one of 12
/// possible types. Each method of the `Serializer` interface corresponds to
/// one of the types of the data model.
///
/// Serializable data types map themselves into this data model by invoking
/// exactly one of the `Serializer` methods.
///
/// The types that make up the Getty data model are:
///
///  - Primitives
///    - bool
///    - float
///    - integer
///  - Non-primitives
///    - array
///    - error set
///    - enum
///    - null
///    - optional
///    - pointer (one, slice)
///    - struct
///    - tagged union
///    - vector
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
