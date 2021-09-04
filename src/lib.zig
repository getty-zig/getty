pub const de = struct {
    pub usingnamespace @import("de.zig").interface;
    pub usingnamespace @import("de.zig").impl;
};

pub const ser = struct {
    pub usingnamespace @import("ser.zig").interface;
    pub usingnamespace @import("ser.zig").impl;
};

pub const deserialize = @import("de.zig").deserialize;
pub const serialize = @import("ser.zig").serialize;
pub const serializeWith = @import("ser.zig").serializeWith;

test {
    @import("std").testing.refAllDecls(@This());
}
