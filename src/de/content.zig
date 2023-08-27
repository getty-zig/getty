const std = @import("std");

const ContentVisitor = @import("impls/visitor/content.zig");

const ContentMap = struct {
    key: Content,
    value: Content,
};

pub const ContentMultiArrayList = std.MultiArrayList(ContentMap);

// Does not support compile-time known types.
pub const Content = union(enum) {
    Bool: bool,
    F16: f16,
    F32: f32,
    F64: f64,
    F128: f128,
    Int: std.math.big.int.Managed,
    Map: ContentMultiArrayList,
    Null,
    Seq: std.ArrayList(Content),
    Some: *Content,
    String: []const u8,
    Void,

    pub fn deinit(self: Content, ally: std.mem.Allocator) void {
        switch (self) {
            .Int => |v| {
                var mut = v;
                mut.deinit();
            },
            .Seq => |v| {
                for (v.items) |elem| elem.deinit(ally);
                v.deinit();
            },
            .Map => |v| {
                for (v.items(.key), v.items(.value)) |key, value| {
                    key.deinit(ally);
                    value.deinit(ally);
                }
                var mut = v;
                mut.deinit(ally);
            },
            .String => |v| ally.free(v),
            .Some => |v| {
                v.deinit(ally);
                ally.destroy(v);
            },
            else => {},
        }
    }

    pub const @"getty.db" = struct {
        pub fn deserialize(
            ally: ?std.mem.Allocator,
            comptime _: type,
            deserializer: anytype,
            visitor: anytype,
        ) !@TypeOf(visitor).Value {
            return try deserializer.deserializeAny(ally, visitor);
        }

        pub fn Visitor(comptime _: type) type {
            return ContentVisitor;
        }

        pub fn free(ally: std.mem.Allocator, comptime _: type, value: anytype) void {
            switch (value) {
                .Int, .Map, .Seq, .String, .Some => value.deinit(ally),
                else => {},
            }
        }
    };
};
