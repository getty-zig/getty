const std = @import("std");

const blocks = @import("../../blocks.zig");
const find_db = @import("../../find.zig").find_db;
const has_attributes = @import("../../../attributes.zig").has_attributes;
const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

pub fn Visitor(comptime Pointer: type) type {
    if (@typeInfo(Pointer) != .Pointer or @typeInfo(Pointer).Pointer.size != .One) {
        @compileError(std.fmt.comptimePrint("expected one pointer, found `{s}`", .{@typeName(Pointer)}));
    }

    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitBool = visitBool,
                .visitFloat = visitFloat,
                .visitInt = visitInt,
                .visitMap = visitMap,
                .visitNull = visitNull,
                .visitSeq = visitSeq,
                .visitSome = visitSome,
                .visitString = visitString,
                .visitUnion = visitUnion,
                .visitVoid = visitVoid,
            },
        );

        const Value = Pointer;
        const Child = std.meta.Child(Value);

        fn visitBool(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: bool,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            value.* = try cv.visitor().visitBool(result_ally, Deserializer, input);

            return value;
        }

        fn visitFloat(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            value.* = try cv.visitor().visitFloat(result_ally, Deserializer, input);

            return value;
        }

        fn visitInt(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            value.* = try cv.visitor().visitInt(result_ally, Deserializer, input);

            return value;
        }

        fn visitMap(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            map: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            value.* = try cv.visitor().visitMap(result_ally, Deserializer, map);

            return value;
        }

        fn visitNull(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            value.* = try cv.visitor().visitNull(result_ally, Deserializer);

            return value;
        }

        fn visitSeq(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            seq: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            value.* = try cv.visitor().visitSeq(result_ally, Deserializer, seq);

            return value;
        }

        fn visitSome(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            deserializer: anytype,
        ) @TypeOf(deserializer).Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(@TypeOf(deserializer)){};
            value.* = try cv.visitor().visitSome(result_ally, deserializer);

            return value;
        }

        fn visitString(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
            lt: StringLifetime,
        ) Deserializer.Err!VisitStringReturn(Value) {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            const result = try cv.visitor().visitString(result_ally, Deserializer, input, lt);

            value.* = result.value;
            return .{ .value = value, .used = result.used };
        }

        fn visitUnion(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            ua: anytype,
            va: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            value.* = try cv.visitor().visitUnion(result_ally, Deserializer, ua, va);

            return value;
        }

        fn visitVoid(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            const value = try result_ally.create(Child);
            errdefer result_ally.destroy(value);

            var cv = ChildVisitor(Deserializer){};
            value.* = try cv.visitor().visitVoid(result_ally, Deserializer);

            return value;
        }

        fn ChildVisitor(comptime Deserializer: type) type {
            const child_db = comptime find_db(Child, Deserializer);

            if (comptime has_attributes(Child, child_db)) {
                return switch (@typeInfo(Child)) {
                    .Enum => blocks.Enum.Visitor(Child),
                    .Struct => blocks.Struct.Visitor(Child),
                    .Union => blocks.Union.Visitor(Child),
                    else => unreachable, // UNREACHABLE: has_attributes guarantees that Child is an enum, struct or union.
                };
            }

            return child_db.Visitor(Child);
        }
    };
}
