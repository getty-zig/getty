//! Compile-time type restraints for various Getty data types.

pub usingnamespace @import("ser/concepts/map.zig");
pub usingnamespace @import("ser/concepts/sbt.zig");
pub usingnamespace @import("ser/concepts/serializer.zig");
pub usingnamespace @import("ser/concepts/seq.zig");
pub usingnamespace @import("ser/concepts/structure.zig");

pub usingnamespace @import("de/concepts/dbt.zig");
pub usingnamespace @import("de/concepts/deserializer.zig");
pub usingnamespace @import("de/concepts/map_access.zig");
pub usingnamespace @import("de/concepts/seed.zig");
pub usingnamespace @import("de/concepts/seq_access.zig");
pub usingnamespace @import("de/concepts/union_access.zig");
pub usingnamespace @import("de/concepts/variant_access.zig");
pub usingnamespace @import("de/concepts/visitor.zig");

pub fn err(comptime concept: []const u8, comptime msg: []const u8) void {
    @compileError("concept `" ++ concept ++ "` was not satisfied: " ++ msg);
}
