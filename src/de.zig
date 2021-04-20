const std = @import("std");

/// A data structure deserializable from any data format supported by Getty.
///
/// Getty provides `Deserialize` implementations for many Zig primitive and
/// standard library types.
///
/// Additionally, Getty provides `Deserialize` implementations for structs and
/// enums that users may import into their program.
pub fn Deserialize(
    comptime Context: type,
    comptime deserializeFn: fn (context: Context, comptime E: type, deserializer: anytype) type!void,
) type {
    return struct {
        const Self = @This();

        context: Context,

        pub fn deserialize(self: Self, comptime Error: type, deserializer: anytype) Error!void {
            return try deserializeFn(self.context, Ok, Error, deserializer);
        }
    };
}

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
pub fn Deserializer(
    comptime Context: type,
    comptime E: type,
    comptime boolFn: fn (context: Context, v: bool) E!void,
) type {
    return struct {
        const Self = @This();

        pub const Error = E;

        context: Context,

        pub fn serialize_bool(self: Self, v: bool) Error!void {
            try boolFn(self.context, v);
        }
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
