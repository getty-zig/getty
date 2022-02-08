const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Optional: type) type {
    return struct {
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

            pub fn visitNull(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                return null;
            }

            pub fn visitSome(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                return try getty.deserialize(allocator, std.meta.Child(Value), deserializer);
            }
        };
    };
}
