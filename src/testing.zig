const std = @import("std");

pub const Token = union(enum) {
    Bool: bool,

    ComptimeInt,
    ComptimeFloat,

    I8: i8,
    I16: i16,
    I32: i32,
    I64: i64,
    I128: i128,

    U8: u8,
    U16: u16,
    U32: u32,
    U64: u64,
    U128: u128,

    F16: f16,
    F32: f32,
    F64: f64,
    F128: f128,

    String: []const u8,
    StringZ: [:0]const u8,

    Null,
    Some,

    Void,

    Seq: struct { len: ?usize },
    SeqEnd,

    Map: struct { len: ?usize },
    MapEnd,

    Struct: struct { name: []const u8, len: usize },
    StructEnd,

    Enum,
    Union,
};
