pub const de = struct {
    pub usingnamespace @import("de/access.zig");
    pub usingnamespace @import("de/deserializer.zig");
    pub usingnamespace @import("de/seed.zig");
    pub usingnamespace @import("de/visitor.zig");

    pub usingnamespace @import("de/impls/seed.zig");
    pub usingnamespace @import("de/impls/visitor.zig");
};

pub const ser = struct {
    pub usingnamespace @import("ser/map.zig");
    pub usingnamespace @import("ser/serializer.zig");
    pub usingnamespace @import("ser/sequence.zig");
    pub usingnamespace @import("ser/struct.zig");

    pub const Tuple = Sequence;
};

pub usingnamespace @import("ser/serialize.zig");
pub usingnamespace @import("de/deserialize.zig");

pub const Attributes = @import("attributes.zig").Attributes;
