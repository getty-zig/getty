const std = @import("std");
const getty = @import("../../../lib.zig");
const visitor = @import("../visitor.zig");

pub fn Visitor(comptime T: type) type {
    if (@typeInfo(T) != .Pointer or @typeInfo(T).Pointer.size != .One) {
        @compileError("expected one pointer, found `" ++ @typeName(T) ++ "`");
    }

    const Value = T;
    const Child = std.meta.Child(T);

    return struct {
        allocator: *std.mem.Allocator,

        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace getty.de.Visitor(
            *Self,
            Value,
            visitBool,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
            const value = try self.allocator.create(Child);
            errdefer self.allocator.destroy(value);

            var v = childVisitor(self.allocator);
            value.* = try v.visitor().visitBool(Error, input);
            return value;
        }

        fn childVisitor(allocator: *std.mem.Allocator) switch (Child) {
            .Array => visitor.ArrayVisitor(Child),
            .Bool => visitor.BoolVisitor,
            .Enum => visitor.EnumVisitor(Child),
            .Float, .ComptimeFloat => visitor.FloatVisitor(Child),
            .Int, .ComptimeInt => visitor.IntVisitor(Child),
            .Optional => visitor.OptionalVisitor(Child),
            .Pointer => |info| switch (info.size) {
                .One => visitor.PointerVisitor(Child),
                .Slice => visitor.SliceVisitor(Child),
                else => @compileError("pointer type is not supported"),
            },
            .Struct => |info| switch (info.is_tuple) {
                false => visitor.StructVisitor(Child),
                true => @compileError("tuple deserialization is not supported"),
            },
            .Void => visitor.VoidVisitor,
            else => unreachable,
        } {
            return switch (Child) {
                .Array => visitor.ArrayVisitor(Child){},
                .Bool => visitor.BoolVisitor{},
                .Enum => visitor.EnumVisitor(Child){},
                .Float, .ComptimeFloat => visitor.FloatVisitor(Child){},
                .Int, .ComptimeInt => visitor.IntVisitor(Child){},
                .Optional => visitor.OptionalVisitor(Child){ .allocator = allocator },
                .Pointer => |info| switch (info.size) {
                    .One => visitor.PointerVisitor(Child){ .allocator = allocator.? },
                    .Slice => visitor.SliceVisitor(Child){ .allocator = allocator.? },
                    else => unreachable,
                },
                .Struct => |info| switch (info.is_tuple) {
                    false => visitor.StructVisitor(Child){ .allocator = allocator },
                    true => unreachable,
                },
                .Void => visitor.VoidVisitor{},
                else => unreachable,
            };
        }
    };
}
