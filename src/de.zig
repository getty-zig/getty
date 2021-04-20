const std = @import("std");

pub const Error = error{Deserialize};

/// A data structure deserializable from any data format supported by Getty.
///
/// Getty provides `Deserialize` implementations for many Zig primitive and
/// standard library types.
///
/// Additionally, Getty provides `Deserialize` implementations for structs and
/// enums that users may import into their program.
pub const Deserialize = struct {
    deserialize_fn: fn (self: *const @This(), deserializer: Deserializer) Error!void,

    /// Deserialize this value from the given Getty deserializer.
    fn deserialize(self: *const @This(), deserializer: Deserializer) Error!void {
        std.debug.print("Deserialize.deserialize\n", .{});
    }
};

/// A data format that can deserialize any data structure supported by Getty.
///
/// The interface defines the deserialization half of the [Getty data model],
/// which is a way to categorize every Zig data structure into one of TODO
/// possible types. Each method of the `Deserializer` interface corresponds to
/// one of the types of the data model.
///
/// The types that make up the Getty data model are:
///
///  - Primitives
///    - bool
///    - i8, i16, i32, i64, i128
///    - u8, u16, u32, u64, u128
///    - f32, f64
pub const Deserializer = struct {
    bool_fn: fn (self: *const @This(), v: bool) void,

    fn deserialize_bool(self: *const @This(), v: bool) void {
        std.debug.print("Deserializer.deserialize_bool\n", .{});
    }
};

test "Deserialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    var d = TestPointr{ .v = true };

    var deserialize = &(@TypeOf(p).de);
    var deserializer = &(@TypeOf(d).deserializer);
    try deserialize.deserialize(deserializer.*);
}

const TestPoint = struct {
    x: i32,
    y: i32,

    const de = Deserialize{ .deserialize_fn = deserialize };

    fn deserialize(self: *const Deserialize, deserializer: Deserializer) Error!void {
        std.log.warn("Deserialize", .{});
    }
};

const TestPointr = struct {
    v: bool,

    const deserializer = Deserializer{
        .bool_fn = deserialize_bool,
    };

    fn deserialize_bool(self: *const Deserializer, v: bool) void {
        std.debug.print("TestPointr.serializeBool\n", .{});
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
