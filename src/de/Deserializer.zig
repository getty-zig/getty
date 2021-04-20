//! A data format that can deserialize any data structure supported by Getty.
//!
//! The interface defines the deserialization half of the [Getty data model],
//! which is a way to categorize every Zig data structure into one of TODO
//! possible types. Each method of the `Deserializer` interface corresponds to
//! one of the types of the data model.
//!
//! The types that make up the Getty data model are:
//!
//!  - Primitives
//!    - bool
//!    - i8, i16, i32, i64, i128
//!    - u8, u16, u32, u64, u128
//!    - f32, f64

const std = @import("std");
const Deserializer = @This();

bool_fn: fn (self: *const @This(), v: bool) void,

/// Deserialize a `bool` value.
pub fn deserialize_bool(self: *const @This(), v: bool) void {
    std.debug.print("Deserializer.deserialize_bool\n", .{});
}
