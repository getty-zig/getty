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
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitBool(allocator, Deserializer, input);

            return value;
        }

        fn visitEnum(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitEnum(allocator, Deserializer, input);

            return value;
        }

        fn visitFloat(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitFloat(allocator, Deserializer, input);

            return value;
        }

        fn visitInt(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitInt(allocator, Deserializer, input);

            return value;
        }

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitMap(allocator, Deserializer, map);

            return value;
        }

        fn visitNull(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitNull(allocator, Deserializer);

            return value;
        }

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitSeq(allocator, Deserializer, seq);

            return value;
        }

        fn visitSome(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, @TypeOf(deserializer)).Visitor(Child){};
            value.* = try child_visitor.visitor().visitSome(allocator, deserializer);

            return value;
        }

        fn visitString(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitString(allocator, Deserializer, input);

            return value;
        }

        fn visitUnion(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitUnion(allocator, Deserializer, ua, va);

            return value;
        }

        fn visitVoid(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            const value = try allocator.?.create(Child);
            errdefer free(allocator.?, value);

            var child_visitor = find_db(Child, Deserializer).Visitor(Child){};
            value.* = try child_visitor.visitor().visitVoid(allocator, Deserializer);

            return value;
        }

        const Child = std.meta.Child(Pointer);
    };
}
