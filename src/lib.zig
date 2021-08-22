pub const de = struct {
    pub usingnamespace @import("de/interfaces/access.zig");
    pub usingnamespace @import("de/interfaces/deserializer.zig");
    pub usingnamespace @import("de/interfaces/seed.zig");
    pub usingnamespace @import("de/interfaces/visitor.zig");

    pub usingnamespace @import("de/impls/seed.zig");
    pub usingnamespace @import("de/impls/visitor.zig");
};

pub const ser = struct {
    pub usingnamespace @import("ser/interfaces/map.zig");
    pub usingnamespace @import("ser/interfaces/serializer.zig");
    pub usingnamespace @import("ser/interfaces/sequence.zig");
    pub usingnamespace @import("ser/interfaces/structure.zig");

    pub const Tuple = Sequence;
};

pub usingnamespace @import("ser/serialize.zig");
pub usingnamespace @import("de/deserialize.zig");

pub const Attributes = @import("attributes.zig").Attributes;
