const getty = @import("../../../lib.zig");

pub fn Visitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub fn visitor(self: *Self) V {
            return .{ .context = self };
        }

        const V = getty.de.Visitor(
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
            visitString,
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

        fn visitSequence(self: *Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitSome(self: *Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;

            return getty.deserialize(@typeInfo(Value).Optional.child, deserializer);
        }

        fn visitString(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }
    };
}
