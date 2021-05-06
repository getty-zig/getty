const json = @import("json.zig");
const std = @import("std");

const mem = std.mem;
const testing = std.testing;

pub fn serialize(comptime S: type, serializer: *S, v: anytype) S.Error!S.Ok {
    const s = serializer.serializer();

    switch (@typeInfo(@TypeOf(v))) {
        .Bool => try s.serialize_bool(v),
        .Int => try s.serialize_int(v),
        .Float => try s.serialize_float(v),
        else => @compileError("unsupported serialize value"),
    }
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
    comptime serializeFn: fn (context: Context, comptime S: type, serializer: anytype) type!type,
) type {
    return struct {
        const Self = @This();

        context: Context,

        pub fn serialize(self: Self, comptime S: type, serializer: *S) S.Error!S.Ok {
            return try serializeFn(self.context, S, serializer);
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
///    - i8, i16, i32, i64, i128
///    - u8, u16, u32, u64, u128
///    - f32, f64
pub fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime boolFn: fn (context: Context, value: bool) E!O,
    comptime intFn: fn (context: Context, value: anytype) E!O,
    comptime floatFn: fn (context: Context, value: anytype) E!O,
) type {
    return struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a `bool` value
        pub fn serialize_bool(self: Self, value: bool) Error!Ok {
            try boolFn(self.context, value);
        }

        /// Serialize an integer value
        pub fn serialize_int(self: Self, value: anytype) Error!Ok {
            if (@typeInfo(@TypeOf(value)) != .Int) {
                @compileError("expected integer, found " ++ @typeName(@TypeOf(value)));
            }

            try intFn(self.context, value);
        }

        /// Serialize a float value
        pub fn serialize_float(self: Self, value: anytype) Error!Ok {
            if (@typeInfo(@TypeOf(value)) != .Float) {
                @compileError("expected float, found " ++ @typeName(@TypeOf(value)));
            }

            try floatFn(self.context, value);
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

const TestPoint = struct {
    x: i32,
    y: i32,

    const Ser = Serialize(@This(), serialize);

    fn ser(self: @This()) Ser {
        return .{ .context = self };
    }

    fn serialize(self: @This(), comptime S: type, serializer: *S) S.Error!S.Ok {
        std.log.warn("TestPoint.serialize\n", .{});
    }
};

comptime {
    testing.refAllDecls(@This());
}
