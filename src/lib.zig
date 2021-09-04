const testing = @import("std").testing;

pub const de = struct {
    // Interfaces
    pub const Deserializer = @import("de/interfaces/deserializer.zig").Deserializer;
    pub const DeserializeSeed = @import("de/interfaces/seed.zig").DeserializeSeed;
    pub const Visitor = @import("de/interfaces/visitor.zig").Visitor;

    pub const SequenceAccess = @import("de/interfaces/access/sequence.zig").Access;

    // Implementations
    pub const Seed = @import("de/impls/seed.zig").Seed;
    pub const BoolVisitor = @import("de/impls/visitors/bool.zig");
    pub const FloatVisitor = @import("de/impls/visitors/float.zig").Visitor;
    pub const IntVisitor = @import("de/impls/visitors/int.zig").Visitor;
    pub const OptionalVisitor = @import("de/impls/visitors/optional.zig");
    pub const VoidVisitor = @import("de/impls/visitors/void.zig");
};

pub const ser = @import("ser.zig");

pub const deserialize = @import("de/deserialize.zig").deserialize;
pub const serialize = @import("ser.zig").serialize;
pub const serializeWith = @import("ser.zig").serializeWith;

test {
    testing.refAllDecls(@This());
}
