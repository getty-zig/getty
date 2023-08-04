const std = @import("std");

const blocks = @import("../../blocks.zig");
const find_db = @import("../../find.zig").find_db;
const free = @import("../../free.zig").free;
const has_attributes = @import("../../../attributes.zig").has_attributes;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

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

        fn visitBool(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitBool(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitFloat(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitFloat(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitInt(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitInt(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitMap(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitMap(a, Deserializer, map);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitNull(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitNull(a, Deserializer);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitSeq(a, Deserializer, seq);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitSome(_: Self, ally: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(@TypeOf(deserializer)){};
                value.* = try cv.visitor().visitSome(a, deserializer);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitString(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitString(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitUnion(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitUnion(a, Deserializer, ua, va);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitVoid(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            if (ally) |a| {
                const value = try a.create(Child);
                errdefer a.destroy(value);

                var cv = ChildVisitor(Deserializer){};
                value.* = try cv.visitor().visitVoid(a, Deserializer);

                return value;
            }

            return error.MissingAllocator;
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
