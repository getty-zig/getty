pub const de = struct {
    // Interfaces
    pub usingnamespace @import("de/interfaces/access.zig");
    pub usingnamespace @import("de/interfaces/deserializer.zig");
    pub usingnamespace @import("de/interfaces/seed.zig");
    pub usingnamespace @import("de/interfaces/visitor.zig");

    // Implementations
    pub usingnamespace @import("de/impls/seed.zig");
    pub const BoolVisitor = @import("de/impls/visitors/bool.zig");
    pub const FloatVisitor = @import("de/impls/visitors/float.zig").Visitor;
    pub const IntVisitor = @import("de/impls/visitors/int.zig").Visitor;
    pub const VoidVisitor = @import("de/impls/visitors/void.zig");
};

pub const ser = struct {
    // Interfaces
    pub usingnamespace @import("ser/interfaces/map.zig");
    pub usingnamespace @import("ser/interfaces/serializer.zig");
    pub usingnamespace @import("ser/interfaces/sequence.zig");
    pub usingnamespace @import("ser/interfaces/structure.zig");
    pub const Tuple = Sequence;
};

pub usingnamespace @import("ser/serialize.zig");
pub usingnamespace @import("de/deserialize.zig");

pub const Attributes = @import("attributes.zig").Attributes;
