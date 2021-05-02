const std = @import("std");

// TODO: Replace unreachable's with a compile error or something.
pub fn serialize(comptime S: type, serializer: *S, v: anytype) S.Error!S.Ok {
    const s = serializer.serializer();

    switch (@typeInfo(@TypeOf(v))) {
        .Bool => try s.serialize_bool(v),
        .Int => |info| try s.serialize_int(v),
        .Float => |info| switch (info.bits) {
            32 => try s.serialize_f32(v),
            64 => try s.serialize_f64(v),
            else => unreachable,
        },
        else => unreachable,
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
    comptime f16Fn: fn (context: Context, value: f16) E!O,
    comptime f32Fn: fn (context: Context, value: f32) E!O,
    comptime f64Fn: fn (context: Context, value: f64) E!O,
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

        /// Serialize a `f16` value
        pub fn serialize_f16(self: Self, value: f16) Error!Ok {
            try f16Fn(self.context, value);
        }

        /// Serialize a `f32` value
        pub fn serialize_f32(self: Self, value: f32) Error!Ok {
            try f32Fn(self.context, value);
        }

        /// Serialize a `f64` value
        pub fn serialize_f64(self: Self, value: f64) Error!Ok {
            try f64Fn(self.context, value);
        }
    };
}

test "Serialize - bool" {
    {
        var serialized = try json.toArrayList(std.testing.allocator, true);
        defer serialized.deinit();

        std.testing.expect(std.mem.eql(u8, serialized.items, "true"));
    }

    {
        var serialized = try json.toArrayList(std.testing.allocator, false);
        defer serialized.deinit();

        std.testing.expect(std.mem.eql(u8, serialized.items, "false"));
    }
}

test "Serialize - integer" {
    const types = [_]type{
        i8, i16, i32, i64,
        u8, u16, u32, u64,
    };

    inline for (types) |T| {
        const max = std.math.maxInt(T);

        var s = try json.toArrayList(std.testing.allocator, @as(T, max));
        defer s.deinit();

        var buffer: [20]u8 = undefined;
        const max_str = std.fmt.bufPrint(&buffer, "{d}", .{max}) catch unreachable;
        std.testing.expect(std.mem.eql(u8, s.items, max_str));
    }
}

const json = @import("serializers/json.zig");

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
    std.testing.refAllDecls(@This());
}
