const getty = @import("../../../lib.zig");

const Allocator = @import("std").mem.Allocator;
const Child = @import("std").meta.Child;

pub fn Visitor(comptime T: type) type {
    return struct {
        allocator: ?*Allocator = null,

        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitNull,
            undefined,
            undefined,
            visitSome,
            undefined,
        );

        const Value = T;

        fn visitNull(self: Self, comptime Error: type) Error!Value {
            _ = self;

            return null;
        }

        fn visitSome(self: Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try getty.deserialize(self.allocator, Child(T), deserializer);
        }
    };
}
