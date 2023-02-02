const std = @import("std");

const find_db = @import("../../find.zig").find_db;
const free = @import("../../free.zig").free;
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
                .visitEnum = visitEnum,
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

        fn visitBool(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitBool(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitEnum(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitEnum(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitFloat(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitFloat(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitInt(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitInt(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitMap(a, Deserializer, map);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitNull(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitNull(a, Deserializer);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitSeq(a, Deserializer, seq);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitSome(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, @TypeOf(deserializer)).Visitor(Child){};
                value.* = try child_visitor.visitor().visitSome(a, deserializer);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitString(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitString(a, Deserializer, input);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitUnion(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitUnion(a, Deserializer, ua, va);

                return value;
            }

            return error.MissingAllocator;
        }

        fn visitVoid(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            if (allocator) |a| {
                const value = try a.create(Child);
                errdefer free(a, value);

                var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
                value.* = try child_visitor.visitor().visitVoid(a, Deserializer);

                return value;
            }

            return error.MissingAllocator;
        }

        const Child = std.meta.Child(Pointer);
    };
}
