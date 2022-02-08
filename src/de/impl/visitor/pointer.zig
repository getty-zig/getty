const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Pointer: type) type {
    if (@typeInfo(Pointer) != .Pointer or @typeInfo(Pointer).Pointer.size != .One) {
        @compileError("expected one pointer, found `" ++ @typeName(Pointer) ++ "`");
    }

    return struct {
        const Self = @This();
        const impl = @"impl Visitor"(Pointer);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            impl.visitor.visitBool,
            impl.visitor.visitEnum,
            impl.visitor.visitFloat,
            impl.visitor.visitInt,
            impl.visitor.visitMap,
            impl.visitor.visitNull,
            impl.visitor.visitSeq,
            impl.visitor.visitString,
            impl.visitor.visitSome,
            impl.visitor.visitVoid,
        );
    };
}

fn @"impl Visitor"(comptime Pointer: type) type {
    const Self = Visitor(Pointer);

    return struct {
        pub const visitor = struct {
            pub const Value = Pointer;

            pub fn visitBool(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitBool(allocator, Deserializer, input);

                return value;
            }

            pub fn visitEnum(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitEnum(allocator, Deserializer, input);

                return value;
            }

            pub fn visitFloat(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitFloat(allocator, Deserializer, input);

                return value;
            }

            pub fn visitInt(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitInt(allocator, Deserializer, input);

                return value;
            }

            pub fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitMap(allocator, Deserializer, map);

                return value;
            }

            pub fn visitNull(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitNull(allocator, Deserializer);

                return value;
            }

            pub fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitSeq(allocator, Deserializer, seq);

                return value;
            }

            pub fn visitString(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitString(allocator, Deserializer, input);

                return value;
            }

            pub fn visitSome(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(@TypeOf(deserializer), Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitSome(allocator, deserializer);

                return value;
            }

            pub fn visitVoid(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                const value = try allocator.?.create(Child);
                errdefer getty.de.free(allocator.?, value);

                var child_visitor = getty.de.find_db(Deserializer, Child).Visitor(Child){};
                value.* = try child_visitor.visitor().visitVoid(allocator, Deserializer);

                return value;
            }

            const Child = std.meta.Child(Pointer);
        };
    };
}
