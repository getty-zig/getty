const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Ignored: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitBool = visitBool,
                .visitFloat = visitAny,
                .visitInt = visitAny,
                .visitMap = visitMap,
                .visitNull = visitNothing,
                .visitSeq = visitSeq,
                .visitSome = visitSome,
                .visitString = visitAny,
                .visitUnion = visitUnion,
                .visitVoid = visitNothing,
            },
        );

        const Value = Ignored;

        fn visitAny(_: Self, _: std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Err!Value {
            return .{};
        }

        fn visitBool(_: Self, _: std.mem.Allocator, comptime Deserializer: type, _: bool) Deserializer.Err!Value {
            return .{};
        }

        fn visitMap(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!Value {
            while ((try map.nextEntry(ally, Ignored, Ignored)) != null) {
                // Gobble
            }

            return .{};
        }

        fn visitSeq(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            while ((try seq.nextElement(ally, Ignored)) != null) {
                // Gobble
            }

            return .{};
        }

        fn visitSome(_: Self, _: std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Err!Value {
            return .{};
        }

        fn visitUnion(_: Self, _: std.mem.Allocator, comptime Deserializer: type, _: anytype, _: anytype) Deserializer.Err!Value {
            return .{};
        }

        fn visitNothing(_: Self, _: std.mem.Allocator, comptime Deserializer: type) Deserializer.Err!Value {
            return .{};
        }
    };
}
