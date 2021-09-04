const testing = @import("std").testing;

pub const de = @import("de.zig");

pub const deserialize = de.deserialize;

pub const ser = struct {
    pub usingnamespace @import("ser.zig").interface;
    pub usingnamespace @import("ser.zig").impl;
};

pub const serialize = @import("ser.zig").serialize;
pub const serializeWith = @import("ser.zig").serializeWith;

test {
    testing.refAllDecls(@This());
}
