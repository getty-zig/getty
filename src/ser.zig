const json = @import("json.zig");
const std = @import("std");

const mem = std.mem;
const testing = std.testing;

pub fn serialize(serializer: anytype, v: anytype) switch (@typeInfo(@TypeOf(serializer))) {
    .Pointer => |info| info.child.Error!info.child.Ok,
    else => @compileError("expected pointer, found " ++ @typeName(@TypeOf(serializer))),
} {
    const s = serializer.serializer();

    return switch (@typeInfo(@TypeOf(v))) {
        .Bool => try s.serialize_bool(v),
        .Int => try s.serialize_int(v),
        .Float => try s.serialize_float(v),
        .Pointer => |info| blk: {
            switch (info.size) {
                .One => {
                    const child_info = @typeInfo(info.child);

                    if (child_info != .Array or child_info.Array.child != u8) {
                        @compileError("pointer does not point to a byte array");
                    }

                    break :blk if (child_info.Array.sentinel) |sentinel| {
                        if (sentinel == 0) try s.serialize_str(v) else try s.serialize_bytes(v);
                    } else {
                        try s.serialize_bytes(v);
                    };
                },
                .Many => unreachable,
                .Slice => unreachable,
                .C => unreachable,
            }

            break :blk try s.serialize_str(v);
        },
        else => @compileError("unsupported serialize value"),
    };
}

/// A data structure serializable into any data format supported by Getty.
///
/// Getty provides `Serialize` implementations for many Zig primitive and
/// standard library types.
///
/// Additionally, Getty provides `Serialize` implementations for structs and
/// enums that users may import into their program.
pub fn Serialize(
    comptime Context: type,
    comptime serializeFn: fn (context: Context, serializer: anytype) type!type,
) type {
    return struct {
        const Self = @This();

        context: Context,

        pub fn serialize(self: Self, serializer: anytype) switch (@typeInfo(@TypeOf(serializer))) {
            .Pointer => |info| info.child.Error!info.child.Ok,
            else => @compileError("expected pointer, found " ++ @typeName(@TypeOf(serializer))),
        } {
            return try serializeFn(self.context, serializer);
        }
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
    comptime strFn: fn (context: Context, value: anytype) E!O,
    comptime bytesFn: fn (context: Context, value: anytype) E!O,
    comptime sequenceFn: fn (context: Context, value: anytype) E!O,
    comptime elementFn: fn (context: Context, value: anytype) E!O,
) type {
    return struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a boolean value
        pub fn serialize_bool(self: Self, value: bool) Error!Ok {
            try boolFn(self.context, value);
        }

        /// Serialize an integer value
        pub fn serialize_int(self: Self, value: anytype) Error!Ok {
            try intFn(self.context, value);
        }

        /// Serialize a float value
        pub fn serialize_float(self: Self, value: anytype) Error!Ok {
            try floatFn(self.context, value);
        }

        pub fn serialize_str(self: Self, value: anytype) Error!Ok {
            try strFn(self.context, value);
        }

        pub fn serialize_bytes(self: Self, value: anytype) Error!Ok {
            try bytesFn(self.context, value);
        }

        pub fn serialize_sequence(self: Self, value: anytype) Error!Ok {
            try sequenceFn(self.context, value);
        }

        pub fn serialize_element(self: Self, value: anytype) Error!Ok {
            try elementFn(self.context, value);
        }
    };
}

test "Serialize - bool" {
    var t = try json.toArrayList(testing.allocator, true);
    defer t.deinit();
    var f = try json.toArrayList(testing.allocator, false);
    defer f.deinit();

    testing.expect(mem.eql(u8, t.items, "true"));
    testing.expect(mem.eql(u8, f.items, "false"));
}

test "Serialize - integer" {
    const types = [_]type{
        i8, i16, i32, i64,
        u8, u16, u32, u64,
    };

    inline for (types) |T| {
        const max = std.math.maxInt(T);
        const min = std.math.minInt(T);

        var max_buf: [20]u8 = undefined;
        var min_buf: [20]u8 = undefined;
        const max_expected = std.fmt.bufPrint(&max_buf, "{}", .{max}) catch unreachable;
        const min_expected = std.fmt.bufPrint(&min_buf, "{}", .{min}) catch unreachable;

        const max_str = try json.toArrayList(testing.allocator, @as(T, max));
        defer max_str.deinit();
        const min_str = try json.toArrayList(testing.allocator, @as(T, min));
        defer min_str.deinit();

        testing.expect(mem.eql(u8, max_str.items, max_expected));
        testing.expect(mem.eql(u8, min_str.items, min_expected));
    }
}

comptime {
    testing.refAllDecls(@This());
}
