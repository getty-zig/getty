const std = @import("std");

/// A data structure serializable into any data format supported by Getty.
///
/// Getty provides `Serialize` implementations for many Zig primitive and
/// standard library types.
///
/// Additionally, Getty provides `Serialize` implementations for structs and
/// enums that users may import into their program.
pub fn Serialize(
    comptime Context: type,
    comptime serializeFn: fn (context: Context, comptime O: type, comptime E: type, serializer: anytype) anyerror!type,
) type {
    return struct {
        const Self = @This();

        context: Context,

        pub fn serialize(self: Self, comptime Ok: type, comptime Error: type, serializer: anytype) Error!Ok {
            return try serializeFn(self.context, Ok, Error, serializer);
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
    comptime boolFn: fn (context: Context, v: bool) E!O,
    comptime i8Fn: fn (context: Context, v: i8) E!O,
    comptime i16Fn: fn (context: Context, v: i16) E!O,
    comptime i32Fn: fn (context: Context, v: i32) E!O,
    comptime i64Fn: fn (context: Context, v: i64) E!O,
    comptime i128Fn: fn (context: Context, v: i128) E!O,
    comptime u8Fn: fn (context: Context, v: u8) E!O,
    comptime u16Fn: fn (context: Context, v: u16) E!O,
    comptime u32Fn: fn (context: Context, v: u32) E!O,
    comptime u64Fn: fn (context: Context, v: u64) E!O,
    comptime u128Fn: fn (context: Context, v: u128) E!O,
    comptime f16Fn: fn (context: Context, v: f16) E!O,
    comptime f32Fn: fn (context: Context, v: f32) E!O,
    comptime f64Fn: fn (context: Context, v: f64) E!O,
) type {
    return struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a `bool` value
        pub fn serialize_bool(self: Self, v: bool) Error!Ok {
            try boolFn(self.context, v);
        }

        /// Serialize a `i8` value
        pub fn serialize_i8(self: Self, v: i8) Error!Ok {
            try i8Fn(self.context, v);
        }

        /// Serialize a `i16` value
        pub fn serialize_i16(self: Self, v: i16) Error!Ok {
            try i16Fn(self.context, v);
        }

        /// Serialize a `i32` value
        pub fn serialize_i32(self: Self, v: i32) Error!Ok {
            try i32Fn(self.context, v);
        }

        /// Serialize a `i64` value
        pub fn serialize_i64(self: Self, v: i64) Error!Ok {
            try i64Fn(self.context, v);
        }

        /// Serialize a `i128` value
        pub fn serialize_i128(self: Self, v: i128) Error!Ok {
            try i128Fn(self.context, v);
        }

        /// Serialize a `u8` value
        pub fn serialize_u8(self: Self, v: u8) Error!Ok {
            try u8Fn(self.context, v);
        }

        /// Serialize a `u16` value
        pub fn serialize_u16(self: Self, v: u16) Error!Ok {
            try u16Fn(self.context, v);
        }

        /// Serialize a `u32` value
        pub fn serialize_u32(self: Self, v: u32) Error!Ok {
            try u32Fn(self.context, v);
        }

        /// Serialize a `u64` value
        pub fn serialize_u64(self: Self, v: u64) Error!Ok {
            try u64Fn(self.context, v);
        }

        /// Serialize a `u128` value
        pub fn serialize_u128(self: Self, v: u128) Error!Ok {
            try u128Fn(self.context, v);
        }

        /// Serialize a `f16` value
        pub fn serialize_f16(self: Self, v: f16) Error!Ok {
            try f16Fn(self.context, v);
        }

        /// Serialize a `f32` value
        pub fn serialize_f32(self: Self, v: f32) Error!Ok {
            try f32Fn(self.context, v);
        }

        /// Serialize a `f64` value
        pub fn serialize_f64(self: Self, v: f64) Error!Ok {
            try f64Fn(self.context, v);
        }
    };
}

test "Serialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    //var s = TestSerializer.init(std.testing.allocator);
    //defer s.deinit();

    var ser = p.ser();
    _ = try ser.serialize(void, error{}, .{});
    //var ser = &(@TypeOf(p).ser);
    //var serializer = &(@TypeOf(s).serializer);
    //try ser.serialize(serializer.*);
    //try serializer.serialize_bool(true);
}

const TestPoint = struct {
    x: i32,
    y: i32,

    const Ser = Serialize(
        *@This(),
        serialize,
    );

    fn ser(self: *@This()) Ser {
        return .{ .context = self };
    }

    fn serialize(self: *@This(), comptime Ok: type, comptime Error: type, serializer: anytype) Error!Ok {
        std.debug.print("TestPoint.serialize\n", .{});
    }
};

//const TestSerializer = struct {
//output: std.ArrayList(u8),

//fn init(allocator: *std.mem.Allocator) @This() {
//return .{ .output = std.ArrayList(u8).init(allocator) };
//}

//fn deinit(self: @This()) void {
//self.output.deinit();
//}

//const serializer = Serializer{
//.bool_fn = serialize_bool,
//.i8_fn = serialize_i8,
//.i16_fn = serialize_i16,
//.i32_fn = serialize_i32,
//.i64_fn = serialize_i64,
//.i128_fn = serialize_i128,
//.u8_fn = serialize_u8,
//.u16_fn = serialize_u16,
//.u32_fn = serialize_u32,
//.u64_fn = serialize_u64,
//.u128_fn = serialize_u128,
//.f16_fn = serialize_f16,
//.f32_fn = serialize_f32,
//.f64_fn = serialize_f64,
//};

//fn serialize_bool(self: *const Serializer, v: bool) Error!void {
//std.log.warn("TestSerializer.serialize_bool", .{});
//}

//fn serialize_i8(self: *const Serializer, v: i8) Error!void {
//std.log.warn("TestSerializer.serialize_i8", .{});
//}

//fn serialize_i16(self: *const Serializer, v: i16) Error!void {
//std.log.warn("TestSerializer.serialize_i16", .{});
//}

//fn serialize_i32(self: *const Serializer, v: i32) Error!void {
//std.log.warn("TestSerializer.serialize_i32", .{});
//}

//fn serialize_i64(self: *const Serializer, v: i64) Error!void {
//std.log.warn("TestSerializer.serialize_i64", .{});
//}

//fn serialize_i128(self: *const Serializer, v: i128) Error!void {
//std.log.warn("TestSerializer.serialize_i128", .{});
//}

//fn serialize_u8(self: *const Serializer, v: u8) Error!void {
//std.log.warn("TestSerializer.serialize_u8", .{});
//}

//fn serialize_u16(self: *const Serializer, v: u16) Error!void {
//std.log.warn("TestSerializer.serialize_u16", .{});
//}

//fn serialize_u32(self: *const Serializer, v: u32) Error!void {
//std.log.warn("TestSerializer.serialize_u32", .{});
//}

//fn serialize_u64(self: *const Serializer, v: u64) Error!void {
//std.log.warn("TestSerializer.serialize_u64", .{});
//}

//fn serialize_u128(self: *const Serializer, v: u128) Error!void {
//std.log.warn("TestSerializer.serialize_u128", .{});
//}

//fn serialize_f16(self: *const Serializer, v: f16) Error!void {
//std.log.warn("TestSerializer.serialize_f16", .{});
//}

//fn serialize_f32(self: *const Serializer, v: f32) Error!void {
//std.log.warn("TestSerializer.serialize_f32", .{});
//}

//fn serialize_f64(self: *const Serializer, v: f64) Error!void {
//std.log.warn("TestSerializer.serialize_f64", .{});
//}
//};

comptime {
    std.testing.refAllDecls(@This());
}
