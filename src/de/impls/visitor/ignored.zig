const std = @import("std");

const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

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
                .visitString = visitString,
                .visitUnion = visitUnion,
                .visitVoid = visitNothing,
            },
        );

        const Value = Ignored;

        fn visitAny(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            _: anytype,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return .{};
        }

        fn visitBool(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            _: bool,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return .{};
        }

        fn visitMap(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            map: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            while ((try map.nextEntry(result_ally, Ignored, Ignored)) != null) {
                // Gobble
            }

            return .{};
        }

        fn visitSeq(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            seq: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            while ((try seq.nextElement(result_ally, Ignored)) != null) {
                // Gobble
            }

            return .{};
        }

        fn visitSome(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            deserializer: anytype,
        ) @TypeOf(deserializer).Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return .{};
        }

        fn visitString(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            _: anytype,
            _: StringLifetime,
        ) Deserializer.Err!VisitStringReturn(Value) {
            _ = result_ally;
            _ = scratch_ally;

            return .{ .value = .{}, .used = false };
        }

        fn visitUnion(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            _: anytype,
            _: anytype,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return .{};
        }

        fn visitNothing(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            return .{};
        }
    };
}
