const interface = @import("../../interface.zig");

const Allocator = @import("std").mem.Allocator;
const math = @import("std").math;
const meta = @import("std").meta;

pub fn Visitor(comptime T: type) type {
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

        const Value = T;

        fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitEnum(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            return input;
        }

        fn visitFloat(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            return meta.intToEnum(Value, input) catch unreachable;
        }

        fn visitMap(self: *Self, allocator: ?*Allocator, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;
            _ = allocator;

            @panic("Unsupported");
        }

        fn visitNull(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitSequence(self: *Self, allocator: ?*Allocator, seqAccess: anytype) @TypeOf(seqAccess).Error!Value {
            _ = self;
            _ = allocator;

            @panic("Unsupported");
        }

        fn visitSlice(self: *Self, allocator: *Allocator, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = allocator;

            return meta.stringToEnum(Value, input) orelse @panic("could not find enum value");
        }

        fn visitSome(self: *Self, allocator: ?*Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
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
