const interface = @import("../../interface.zig");

const Allocator = @import("std").mem.Allocator;
const math = @import("std").math;

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
            _ = input;

            @panic("Unsupported");
        }

        fn visitFloat(_: *Self, comptime Error: type, input: anytype) Error!Value {
            if (math.round(input) != input or (input > math.maxInt(T) or input < math.minInt(T))) {
                @panic("Failure during float-to-int cast");
            }

            return @floatToInt(T, input);
        }

        fn visitInt(_: *Self, comptime Error: type, input: anytype) Error!Value {
            return @intCast(T, input);
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
            _ = input;

            @panic("Unsupported");
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
