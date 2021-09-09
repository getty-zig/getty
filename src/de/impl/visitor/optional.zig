const getty = @import("../../../lib.zig");

const Allocator = @import("std").mem.Allocator;
const Child = @import("std").meta.Child;

pub fn Visitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace getty.de.Visitor(
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

        const Value = T;

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

            return null;
        }

        fn visitSequence(self: *Self, seqAccess: anytype) @TypeOf(seqAccess).Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitSome(self: *Self, allocator: ?*Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;

            return try getty.deserialize(allocator, Child(T), deserializer);
        }

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }
    };
}
