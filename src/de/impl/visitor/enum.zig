const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Enum: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            visitEnum,
            undefined,
            visitInt,
            undefined,
            undefined,
            undefined,
            visitString,
            undefined,
            undefined,
        );

        const Value = Enum;

        fn visitEnum(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return input;
        }

        fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return std.meta.intToEnum(Value, input) catch unreachable;
        }

        fn visitString(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            defer getty.de.free(allocator.?, input);
            return std.meta.stringToEnum(Value, input) orelse return error.UnknownVariant;
        }
    };
}
