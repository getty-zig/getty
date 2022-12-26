const std = @import("std");

const de = @import("../../../de.zig").de;

pub fn Visitor(comptime Ignored: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{
                .visitBool = visitBool,
                .visitEnum = visitAny,
                .visitFloat = visitAny,
                .visitInt = visitAny,
                .visitMap = visitAny,
                .visitNull = visitNothing,
                .visitSeq = visitAny,
                .visitSome = visitSome,
                .visitString = visitAny,
                .visitUnion = visitUnion,
                .visitVoid = visitNothing,
            },
        );

        const Value = Ignored;

        fn visitBool(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, _: bool) Deserializer.Error!Value {
            return .{};
        }

        fn visitAny(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            return .{};
        }
        fn visitSome(_: Self, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return .{};
        }

        fn visitUnion(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype, _: anytype) Deserializer.Error!Value {
            return .{};
        }

        fn visitNothing(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            return .{};
        }
    };
}
