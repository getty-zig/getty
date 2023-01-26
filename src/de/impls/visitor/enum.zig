const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Enum: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitEnum = visitEnum,
                .visitInt = visitInt,
                .visitString = visitString,
            },
        );

        const Value = Enum;

        fn visitEnum(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return input;
        }

        fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return std.meta.intToEnum(Value, input) catch error.InvalidValue;
        }

        fn visitString(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return std.meta.stringToEnum(Value, input) orelse return error.UnknownVariant;
        }
    };
}
