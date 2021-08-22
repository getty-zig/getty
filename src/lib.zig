pub const de = struct {
    pub usingnamespace @import("de/access.zig");
    pub usingnamespace @import("de/deserializer.zig");
    pub usingnamespace @import("de/seed.zig");
    pub usingnamespace @import("de/visitor.zig");

    pub usingnamespace @import("de/impls/seed.zig");
    pub usingnamespace @import("de/impls/visitor.zig");
};

pub const ser = @import("ser.zig");

pub const serialize = ser.serialize;
pub usingnamespace @import("de/deserialize.zig");

pub const Attributes = @import("attributes.zig").Attributes;
