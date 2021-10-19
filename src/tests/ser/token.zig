const std = @import("std");

pub const Token = union(enum) {
    Bool: bool,

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

    //ComptimeInt: comptime_int,
    //ComptimeFloat: comptime_float,

    String: []const u8,

    Null,
    Some,

    Void,

    Seq: struct { len: ?usize },
    SeqEnd,

    Tuple: struct { len: usize },
    TupleEnd,

    Map: struct { len: ?usize },
    MapEnd,

    Struct: struct { name: []const u8, len: usize },
    StructEnd,

    Enum: struct { name: []const u8, variant: []const u8 },
};
