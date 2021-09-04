const testing = @import("std").testing;

pub const de = @import("de.zig");
pub const ser = @import("ser.zig");

pub const deserialize = @import("de.zig").deserialize;
pub const serialize = @import("ser.zig").serialize;
pub const serializeWith = @import("ser.zig").serializeWith;

test {
    testing.refAllDecls(@This());
}
