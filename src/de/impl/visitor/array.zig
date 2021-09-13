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
            visitSlice,
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

        fn visitMap(self: *Self, allocator: ?*std.mem.Allocator, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;
            _ = allocator;

            @panic("Unsupported");
        }

        fn visitNull(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitSequence(self: *Self, allocator: ?*std.mem.Allocator, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            _ = self;
            _ = allocator;

            var arr: Value = undefined;
            var i: usize = 0;

            while (try sequenceAccess.nextElement(std.meta.Child(Value))) |elem| : (i += 1) {
                arr[i] = elem;
            }

            if (i != arr.len) {
                @panic("unexpected end of sequence");
            }

            return arr;
        }

        fn visitSlice(self: *Self, allocator: *std.mem.Allocator, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = allocator;
            _ = input;

            @panic("Unsupported");
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
