const getty = @import("../../../lib.zig");

const Allocator = @import("std").mem.Allocator;
const Child = @import("std").meta.Child;

pub fn Visitor(comptime Optional: type) type {
    return struct {
        allocator: ?Allocator = null,

        const Self = @This();
        const impl = @"impl Visitor"(Optional);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            impl.visitor.visitNull,
            undefined,
            undefined,
            impl.visitor.visitSome,
            undefined,
        );
    };
}

fn @"impl Visitor"(comptime Optional: type) type {
    const Self = Visitor(Optional);

    return struct {
        pub const visitor = struct {
            pub const Value = Optional;

            pub fn visitNull(_: Self, comptime Deserializer: type) Deserializer.Error!Value {
                return null;
            }

            pub fn visitSome(self: Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                return try getty.deserialize(self.allocator, Child(Value), deserializer);
            }
        };
    };
}
