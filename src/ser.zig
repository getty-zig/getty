const std = @import("std");

pub fn serialize(serializer: anytype, v: anytype) @typeInfo(@TypeOf(serializer)).Pointer.child.Error!@typeInfo(@TypeOf(serializer)).Pointer.child.Ok {
    const s = serializer.serializer();

    return switch (@typeInfo(@TypeOf(v))) {
        .Array => try serialize(serializer, &v),
        .Bool => try s.serializeBool(v),
        //.Enum => try s.serializeEnum(v),
        .ErrorSet => try serialize(serializer, @as([]const u8, @errorName(v))),
        .Float, .ComptimeFloat => try s.serializeFloat(v),
        .Int, .ComptimeInt => try s.serializeInt(v),
        .Null => try s.serializeNull(v),
        .Optional => if (v) |payload| try serialize(serializer, payload) else try serialize(serializer, null),
        .Pointer => |info| switch (info.size) {
            .One => switch (@typeInfo(info.child)) {
                .Array => try serialize(serializer, @as([]const std.meta.Elem(info.child), v)),
                else => try serialize(serializer, v.*),
            },
            .Slice => try s.serializeSlice(v),
            else => @compileError("unsupported serialize type: " ++ @typeName(@TypeOf(v))),
        },
        //.Struct => |S| {},
        //.Union => {},
        .Vector => |info| {
            const array: [info.len]info.child = v;
            try serialize(serializer, &array);
        },
        else => @compileError("unsupported serialize type: " ++ @typeName(@TypeOf(v))),
    };
}

/// A data format that can serialize any data structure supported by Getty.
///
/// The interface defines the serialization half of the [Getty data model],
/// which is a way to categorize every Zig data structure into one of TODO
/// possible types. Each method of the `Serializer` interface corresponds to
/// one of the types of the data model.
///
/// Implementations of `Serialize` map themselves into this data model by
/// invoking exactly one of the `Serializer` methods.
///
/// The types that make up the Getty data model are:
///
///  - Primitives
///    - bool
///    - iN (where N is any supported signed integer bit-width)
///    - uN (where N is any supported unsigned integer bit-width)
///    - fN (where N is any supported floating-point bit-width)
pub fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime boolFn: fn (context: Context, value: bool) E!O,
    comptime intFn: fn (context: Context, value: anytype) E!O,
    comptime floatFn: fn (context: Context, value: anytype) E!O,
    comptime nullFn: fn (context: Context, value: anytype) E!O,
    comptime sliceFn: fn (context: Context, value: anytype) E!O,
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

        /// Serialize a slice value.
        pub fn serializeSlice(self: Self, value: anytype) Error!Ok {
            return try sliceFn(self.context, value);
        }
    };
}
