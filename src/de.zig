const std = @import("std");

pub fn Deserializer(
    comptime Context: type,
    comptime E: type,
    comptime anyFn: fn (context: Context, value: bool) E!O,
    comptime boolFn: fn (context: Context, value: bool) E!O,
    comptime elementFn: fn (context: Context, value: anytype) E!O,
    comptime fieldFn: fn (context: Context, comptime key: []const u8, value: anytype) E!O,
    comptime floatFn: fn (context: Context, value: anytype) E!O,
    comptime intFn: fn (context: Context, value: anytype) E!O,
    comptime nullFn: fn (context: Context, value: anytype) E!O,
    comptime sequenceFn: fn (context: Context) E!fn (Context) E!O,
    comptime stringFn: fn (context: Context, value: anytype) E!O,
    comptime structFn: fn (context: Context) E!fn (Context) E!O,
    comptime variantFn: fn (context: Context, value: anytype) E!O,
) type {
    return struct {};
}

comptime {
    std.testing.refAllDecls(@This());
}
