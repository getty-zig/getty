//! A visitor for the std.mem.Allocator type.
//!
//! This visitor should never actually be used. The deserialization block that
//! uses this visitor always raises a compile error. It never calls any methods
//! on this visitor.

const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub usingnamespace VisitorInterface(
    @This(),
    std.mem.Allocator,
    .{},
);
