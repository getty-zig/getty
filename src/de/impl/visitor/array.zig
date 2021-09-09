const std = @import("std");

const interface = @import("../../interface.zig");

pub fn Visitor(comptime Value: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace interface.Visitor(
            *Self,
            Value,
            visitBool,
            visitEnum,
            visitFloat,
            visitInt,
            visitMap,
            visitNull,
            visitSequence,
            visitSome,
            visitVoid,
        );

        fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitEnum(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitFloat(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitMap(self: *Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitNull(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitSequence(self: *Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            _ = self;

            var arr: Value = undefined;

            for (arr) |*v| {
                if (try sequenceAccess.nextElement(std.meta.Child(@TypeOf(v)))) |elem| {
                    v.* = elem;
                }
            }

            return arr;
        }

        fn visitSome(self: *Self, allocator: ?*std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;
            _ = allocator;

            @panic("Unsupported");
        }

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }
    };
}
