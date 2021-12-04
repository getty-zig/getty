const std = @import("std");
const getty = @import("../../../lib.zig");

const ArrayVisitor = @import("array.zig").Visitor;
const BoolVisitor = @import("bool.zig");
const EnumVisitor = @import("enum.zig").Visitor;
const FloatVisitor = @import("float.zig").Visitor;
const IntVisitor = @import("int.zig").Visitor;
const OptionalVisitor = @import("optional.zig").Visitor;
const SliceVisitor = @import("slice.zig").Visitor;
const StructVisitor = @import("struct.zig").Visitor;
const VoidVisitor = @import("void.zig");

pub fn Visitor(comptime Pointer: type) type {
    if (@typeInfo(Pointer) != .Pointer or @typeInfo(Pointer).Pointer.size != .One) {
        @compileError("expected one pointer, found `" ++ @typeName(Pointer) ++ "`");
    }

    return struct {
        allocator: *std.mem.Allocator,

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
            impl.visitor.visitSequence,
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

            pub fn visitBool(self: Self, comptime Error: type, input: bool) Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitBool(Error, input);
                return value;
            }

            pub fn visitEnum(self: Self, comptime Error: type, input: anytype) Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitEnum(Error, input);
                return value;
            }

            pub fn visitFloat(self: Self, comptime Error: type, input: anytype) Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitFloat(Error, input);
                return value;
            }

            pub fn visitInt(self: Self, comptime Error: type, input: anytype) Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitInt(Error, input);
                return value;
            }

            pub fn visitMap(self: Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitMap(mapAccess);
                return value;
            }

            pub fn visitNull(self: Self, comptime Error: type) Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitNull(Error);
                return value;
            }

            pub fn visitSequence(self: Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitSequence(sequenceAccess);
                return value;
            }

            pub fn visitString(self: Self, comptime Error: type, input: anytype) Error!Value {
                const value = try self.allocator.create(Child);
                errdefer self.allocator.destroy(value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitString(Error, input);
                return value;
            }

            pub fn visitSome(self: Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitSome(deserializer);
                return value;
            }

            pub fn visitVoid(self: Self, comptime Error: type) Error!Value {
                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);

                var v = childVisitor(self.allocator);
                value.* = try v.visitor().visitVoid(Error);
                return value;
            }

            fn childVisitor(allocator: *std.mem.Allocator) ChildVisitor {
                return switch (@typeInfo(Child)) {
                    .Bool, .ComptimeFloat, .ComptimeInt, .Float, .Int, .Void => .{},
                    .Array, .Enum, .Optional, .Pointer, .Struct => .{ .allocator = allocator },
                    else => unreachable,
                };
            }

            const Child = std.meta.Child(Pointer);

            const ChildVisitor = switch (@typeInfo(Child)) {
                .Array => ArrayVisitor(Child),
                .Bool => BoolVisitor,
                .Enum => EnumVisitor(Child),
                .Float, .ComptimeFloat => FloatVisitor(Child),
                .Int, .ComptimeInt => IntVisitor(Child),
                .Optional => OptionalVisitor(Child),
                .Pointer => |info| switch (info.size) {
                    .One => Visitor(Child),
                    .Slice => SliceVisitor(Child),
                    else => @compileError("pointer type is not supported"),
                },
                .Struct => |info| switch (info.is_tuple) {
                    false => StructVisitor(Child),
                    true => @compileError("tuple deserialization is not supported"),
                },
                .Void => VoidVisitor,
                else => @compileError("type `" ++ @typeName(Child) ++ "` is not supported"),
            };
        };
    };
}
